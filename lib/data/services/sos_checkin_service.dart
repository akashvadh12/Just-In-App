// File: lib/services/sos_check_in_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';

enum CheckInStatus { allOk, sos, ignored, pending }

class SosCheckInService extends GetxController {
  static SosCheckInService get instance => Get.find<SosCheckInService>();
  
  final ProfileController profileController = Get.find<ProfileController>();
  final ConnectivityController connectivityController = Get.find<ConnectivityController>();
  final LocalStorageService _storage = LocalStorageService.instance;
  
  // Configuration - these would normally come from API
  final RxInt checkInIntervalMinutes = 10.obs;
  final RxInt responseWindowMinutes = 2.obs;
  final RxBool isServiceActive = false.obs;
  final RxBool isCheckInPending = false.obs;
  final RxString lastCheckInTime = ''.obs;
  final RxInt missedCheckIns = 0.obs;
  
  Timer? _checkInTimer;
  Timer? _responseTimer;
  DateTime? _lastCheckInSent;
  
  // Demo API endpoints - replace with actual ones
  static const String _baseUrl = 'https://demo-api.security-guard.com';
  static const String _checkInEndpoint = '/api/sos/check-in';
  static const String _alertEndpoint = '/api/sos/alert';
  static const String _configEndpoint = '/api/sos/config';
  
  @override
  void onInit() {
    super.onInit();
    _loadConfiguration();
  }
  
  @override
  void onClose() {
    stopService();
    super.onClose();
  }
  
  /// Start the SOS check-in service
  void startService() {
    if (isServiceActive.value) return;
    
    isServiceActive.value = true;
    _scheduleNextCheckIn();
    
    Get.snackbar(
      'SOS Service Started',
      'Periodic safety check-ins are now active',
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      icon: const Icon(Icons.security, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
    
    print('✅ SOS Check-in service started');
  }
  
  /// Stop the SOS check-in service
  void stopService() {
    isServiceActive.value = false;
    _checkInTimer?.cancel();
    _responseTimer?.cancel();
    isCheckInPending.value = false;
    
    Get.snackbar(
      'SOS Service Stopped',
      'Periodic safety check-ins have been disabled',
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
      icon: const Icon(Icons.security_outlined, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
    
    print('🛑 SOS Check-in service stopped');
  }
  
  /// Load configuration from API
  Future<void> _loadConfiguration() async {
    try {
      if (connectivityController.isOffline.value) {
        print('📱 SOS Service: Using default configuration (offline)');
        return;
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl$_configEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getUserToken()}',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        checkInIntervalMinutes.value = data['checkInIntervalMinutes'] ?? 30;
        responseWindowMinutes.value = data['responseWindowMinutes'] ?? 2;
        
        print('✅ SOS Configuration loaded: CheckIn=${checkInIntervalMinutes.value}min, Response=${responseWindowMinutes.value}min');
      } else {
        print('⚠️ Failed to load SOS config: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading SOS configuration: $e');
      // Continue with default values
    }
  }
  
  /// Schedule the next check-in
  void _scheduleNextCheckIn() {
    if (!isServiceActive.value) return;
    
    _checkInTimer?.cancel();
    _checkInTimer = Timer(
      Duration(minutes: checkInIntervalMinutes.value),
      _showCheckInDialog,
    );
    
    final nextTime = DateTime.now().add(Duration(minutes: checkInIntervalMinutes.value));
    print('⏰ Next SOS check-in scheduled for: ${_formatDateTime(nextTime)}');
  }
  
  /// Show the check-in dialog
  void _showCheckInDialog() {
    if (!isServiceActive.value) return;
    
    isCheckInPending.value = true;
    _lastCheckInSent = DateTime.now();
    
    print('🔔 Showing SOS check-in dialog');
    
    // Start response timer
    _responseTimer = Timer(
      Duration(minutes: responseWindowMinutes.value),
      _handleNoResponse,
    );
    
    Get.dialog(
      const SosCheckInDialog(),
      barrierDismissible: false,
      name: 'SosCheckInDialog',
    );
  }
  
  /// Handle user response to check-in
  Future<void> handleCheckInResponse(CheckInStatus status) async {
    print('📝 SOS Check-in response: ${status.toString()}');
    
    _responseTimer?.cancel();
    isCheckInPending.value = false;
    
    try {
      await _sendCheckInResponse(status);
      
      if (status != CheckInStatus.ignored) {
        Get.back(); // Close dialog
      }
      
      if (status == CheckInStatus.allOk) {
        lastCheckInTime.value = _formatDateTime(DateTime.now());
        missedCheckIns.value = 0;
        _scheduleNextCheckIn();
        
        Get.snackbar(
          '✅ Check-in Successful',
          'Thank you for confirming your safety',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      } else if (status == CheckInStatus.sos) {
        _handleSosAlert();
      } else if (status == CheckInStatus.ignored) {
        Get.back(); // Close dialog
        _scheduleNextCheckIn(); // Continue with normal schedule
        
        Get.snackbar(
          'Check-in Ignored',
          'Check-in was dismissed. Next check-in scheduled.',
          backgroundColor: Colors.grey.withOpacity(0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
      
    } catch (e) {
      print('❌ Error handling check-in response: $e');
      Get.snackbar(
        'Check-in Error',
        'Failed to send response. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }
  
  /// Handle no response within time window
  void _handleNoResponse() {
    if (!isCheckInPending.value) return;
    
    print('⏰ SOS Check-in timeout - no response received');
    
    isCheckInPending.value = false;
    missedCheckIns.value++;
    
    Get.back(); // Close dialog if still open
    
    _sendMissedCheckInAlert();
    _scheduleNextCheckIn();
    
    Get.snackbar(
      '⚠️ Missed Check-in',
      'No response received. Alert sent to admin.',
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }
  
  /// Send check-in response to API
  Future<void> _sendCheckInResponse(CheckInStatus status) async {
    if (connectivityController.isOffline.value) {
      throw Exception('No internet connection');
    }
    
    final payload = {
      'userId': await _getUserId(),
      'status': status.toString().split('.').last,
      'timestamp': DateTime.now().toIso8601String(),
      'location': await _getCurrentLocation(),
      'deviceInfo': await _getDeviceInfo(),
    };
    
    print('📤 Sending check-in response: ${payload['status']}');
    
    final response = await http.post(
      Uri.parse('$_baseUrl$_checkInEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getUserToken()}',
      },
      body: json.encode(payload),
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    
    print('✅ Check-in response sent successfully');
  }
  
  /// Send SOS alert
  void _handleSosAlert() {
    Get.back(); // Close dialog
    
    Get.snackbar(
      '🆘 SOS Alert Sent',
      'Emergency alert has been sent to admin and authorities',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.emergency, color: Colors.white),
      duration: const Duration(seconds: 5),
    );
    
    _sendSosAlert();
    // Don't schedule next check-in for SOS - let admin handle
  }
  
  /// Send SOS alert to API
  Future<void> _sendSosAlert() async {
    try {
      final payload = {
        'userId': await _getUserId(),
        'alertType': 'SOS',
        'timestamp': DateTime.now().toIso8601String(),
        'location': await _getCurrentLocation(),
        'priority': 'CRITICAL',
        'deviceInfo': await _getDeviceInfo(),
      };
      
      print('🚨 Sending SOS alert');
      
      final response = await http.post(
        Uri.parse('$_baseUrl$_alertEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getUserToken()}',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));
      
      print('✅ SOS alert sent: ${response.statusCode}');
    } catch (e) {
      print('❌ Error sending SOS alert: $e');
    }
  }
  
  /// Send missed check-in alert
  Future<void> _sendMissedCheckInAlert() async {
    try {
      final payload = {
        'userId': await _getUserId(),
        'alertType': 'MISSED_CHECKIN',
        'timestamp': DateTime.now().toIso8601String(),
        'missedCount': missedCheckIns.value,
        'lastCheckIn': lastCheckInTime.value,
        'location': await _getCurrentLocation(),
        'priority': missedCheckIns.value > 2 ? 'HIGH' : 'MEDIUM',
      };
      
      print('📢 Sending missed check-in alert (${missedCheckIns.value} missed)');
      
      final response = await http.post(
        Uri.parse('$_baseUrl$_alertEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getUserToken()}',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));
      
      print('✅ Missed check-in alert sent: ${response.statusCode}');
    } catch (e) {
      print('❌ Error sending missed check-in alert: $e');
    }
  }
  
  /// Get current location (mock implementation)
  Future<Map<String, double>> _getCurrentLocation() async {
    // TODO: Replace with actual location service
    // Example using geolocator package:
    Position position = await Geolocator.getCurrentPosition();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
    
    // return {
    //   'latitude': 21.2514, // Raipur coordinates
    //   'longitude': 81.6296,
    // };
  }
  
  /// Get device information
  Future<String> _getDeviceInfo() async {
    // TODO: Replace with actual device info
    // Example using device_info_plus package:
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // if (Platform.isAndroid) {
    //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    //   return '${androidInfo.brand} ${androidInfo.model}';
    // }
    
    return 'Demo Device';
  }
  
  /// Helper methods
  Future<String> _getUserId() async {
    String? userId = await _storage.getUserId();
    if (userId == null || userId.isEmpty) {
      userId = profileController.userModel.value?.userId ?? '';
    }
    return userId;
  }
  
  Future<String> _getUserToken() async {
    // TODO: Replace with actual token retrieval
    return 'demo_token_123';
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
  
  /// Update configuration
  void updateConfiguration({int? intervalMinutes, int? responseMinutes}) {
    bool needsRestart = false;
    
    if (intervalMinutes != null && intervalMinutes != checkInIntervalMinutes.value) {
      checkInIntervalMinutes.value = intervalMinutes;
      needsRestart = true;
      print('📝 Updated check-in interval to $intervalMinutes minutes');
    }
    
    if (responseMinutes != null && responseMinutes != responseWindowMinutes.value) {
      responseWindowMinutes.value = responseMinutes;
      print('📝 Updated response window to $responseMinutes minutes');
    }
    
    // Restart service with new configuration
    if (needsRestart && isServiceActive.value) {
      print('🔄 Restarting SOS service with new configuration');
      stopService();
      startService();
    }
  }
  
  /// Get service status summary
  Map<String, dynamic> getServiceStatus() {
    return {
      'isActive': isServiceActive.value,
      'isPending': isCheckInPending.value,
      'checkInInterval': checkInIntervalMinutes.value,
      'responseWindow': responseWindowMinutes.value,
      'lastCheckIn': lastCheckInTime.value,
      'missedCount': missedCheckIns.value,
      'nextCheckIn': isServiceActive.value 
          ? DateTime.now().add(Duration(minutes: checkInIntervalMinutes.value)).toIso8601String()
          : null,
    };
  }
}

/// SOS Check-in Dialog Widget
class SosCheckInDialog extends StatefulWidget {
  const SosCheckInDialog({Key? key}) : super(key: key);
  
  @override
  State<SosCheckInDialog> createState() => _SosCheckInDialogState();
}

class _SosCheckInDialogState extends State<SosCheckInDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _timerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _timerAnimation;
  
  final SosCheckInService sosService = SosCheckInService.instance;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: Duration(minutes: sosService.responseWindowMinutes.value),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear),
    );
    
    _pulseController.repeat(reverse: true);
    _timerController.forward();
    
    print('🔔 SOS Check-in dialog initialized');
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _timerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer indicator
              AnimatedBuilder(
                animation: _timerAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: _timerAnimation.value,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _timerAnimation.value > 0.5 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time remaining: ${(_timerAnimation.value * sosService.responseWindowMinutes.value).ceil()} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Pulsing security icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Safety Check-In',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'Please confirm your status within the response window',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 30),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.check_circle,
                      label: 'All OK',
                      color: Colors.green,
                      onTap: () => sosService.handleCheckInResponse(CheckInStatus.allOk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.emergency,
                      label: 'SOS',
                      color: Colors.red,
                      onTap: () => sosService.handleCheckInResponse(CheckInStatus.sos),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => sosService.handleCheckInResponse(CheckInStatus.ignored),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Ignore',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}