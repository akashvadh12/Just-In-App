// File: lib/services/sos_check_in_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/core/api/api_constants.dart';
import 'package:security_guard/core/api/api_service.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/data/services/background_sos_service.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'dart:developer' as dev;

enum CheckInStatus { allOk, sos, ignored, pending }

class SosCheckInService extends GetxController {
  static SosCheckInService get instance => Get.find<SosCheckInService>();

  final ProfileController profileController = Get.find<ProfileController>();
  final ConnectivityController connectivityController =
      Get.find<ConnectivityController>();
  final LocalStorageService _storage = LocalStorageService.instance;
  final ApiGetServices _apiService = Get.find<ApiGetServices>();

  // Configuration - these would normally come from API
  final RxInt checkInIntervalMinutes = 1.obs;
  final RxInt responseWindowMinutes = 1.obs;
  final RxBool isServiceActive = false.obs;
  final RxBool isCheckInPending = false.obs;
  final RxString lastCheckInTime = ''.obs;
  final RxInt missedCheckIns = 0.obs;
  final RxBool isSubmittingCheckIn = false.obs;

  Timer? _checkInTimer;
  Timer? _responseTimer;
  DateTime? _lastCheckInSent;
  DateTime? _currentPromptTime;

  static const String _logTag = '[SosCheckInService]';

  // Queue for offline check-ins
  final List<Map<String, dynamic>> _pendingCheckIns = [];

  @override
  void onInit() {
    super.onInit();
    _loadConfiguration();
    _setupConnectivityListener();
  }

  @override
  void onClose() {
    stopService();
    super.onClose();
  }

  /// Setup connectivity listener to process pending check-ins when online
  void _setupConnectivityListener() {
    ever(connectivityController.isOffline, (bool isOffline) {
      if (!isOffline && _pendingCheckIns.isNotEmpty) {
        _processPendingCheckIns();
      }
    });
  }

  /// Process pending check-ins when connection is restored
  Future<void> _processPendingCheckIns() async {
    if (_pendingCheckIns.isEmpty) return;

    dev.log('$_logTag Processing ${_pendingCheckIns.length} pending check-ins');

    final checkInsToProcess = List<Map<String, dynamic>>.from(_pendingCheckIns);
    _pendingCheckIns.clear();

    for (final checkInData in checkInsToProcess) {
      try {
        await _sendCheckInToApi(checkInData);
        dev.log(
          '$_logTag Successfully sent pending check-in: ${checkInData['response']}',
        );
      } catch (e) {
        dev.log('$_logTag Failed to send pending check-in: $e');
        // Re-queue if still fails
        _pendingCheckIns.add(checkInData);
      }
    }

    if (_pendingCheckIns.isEmpty) {
      Get.snackbar(
        'Check-ins Synced',
        'All pending safety check-ins have been sent',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.cloud_done, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> startBackgroundService() async {
    await BackgroundSosService.startBackgroundService(
      intervalMinutes: 1,
      responseWindowMinutes: 2,
      userId: await _getUserId(),
    );
  }

  /// Stop background SOS service
  Future<void> stopBackgroundService() async {
    await BackgroundSosService.stopBackgroundService();
  }

  /// Start the SOS check-in service
  void startService() {
    if (isServiceActive.value) return;

    isServiceActive.value = true;
    _scheduleNextCheckIn();
    startBackgroundService();

    Get.snackbar(
      'SOS Service Started',
      'Periodic safety check-ins are now active',
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      icon: const Icon(Icons.security, color: Colors.white),
      duration: const Duration(seconds: 2),
    );

    dev.log('$_logTag SOS Check-in service started');
  }

  /// Stop the SOS check-in service
  void stopService() {
    isServiceActive.value = false;
    _checkInTimer?.cancel();
    _responseTimer?.cancel();
    isCheckInPending.value = false;

    stopBackgroundService();
    Get.snackbar(
      'SOS Service Stopped',
      'Periodic safety check-ins have been disabled',
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
      icon: const Icon(Icons.security_outlined, color: Colors.white),
      duration: const Duration(seconds: 3),
    );

    dev.log('$_logTag SOS Check-in service stopped');
  }

  /// Load configuration from API
  Future<void> _loadConfiguration() async {
    try {
      if (connectivityController.isOffline.value) {
        dev.log('$_logTag Using default configuration (offline)');
        return;
      }

      // You can load these from API or settings
      checkInIntervalMinutes.value = 1;
      responseWindowMinutes.value = 1;

      dev.log(
        '$_logTag Configuration loaded: CheckIn=${checkInIntervalMinutes.value}min, Response=${responseWindowMinutes.value}min',
      );
    } catch (e) {
      dev.log('$_logTag Error loading SOS configuration: $e');
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

    final nextTime = DateTime.now().add(
      Duration(minutes: checkInIntervalMinutes.value),
    );
    dev.log(
      '$_logTag Next SOS check-in scheduled for: ${_formatDateTime(nextTime)}',
    );
  }

  /// Show the check-in dialog
  void _showCheckInDialog() {
    if (!isServiceActive.value) return;

    isCheckInPending.value = true;
    _lastCheckInSent = DateTime.now();
    _currentPromptTime = DateTime.now(); // Store the prompt time

    dev.log('$_logTag Showing SOS check-in dialog');

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
    dev.log('$_logTag SOS Check-in response: ${status.toString()}');

    _responseTimer?.cancel();
    isCheckInPending.value = false;

    try {
      // Send check-in response to API
      await _sendCheckInResponse(status);

      if (status != CheckInStatus.ignored) {
        Get.back();
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
      dev.log('$_logTag Error handling check-in response: $e');
      Get.snackbar(
        'Check-in Error',
        'Failed to send response. It will be sent when connection is restored.',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.cloud_off, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Handle no response within time window
  void _handleNoResponse() {
    if (!isCheckInPending.value) return;

    dev.log('$_logTag SOS Check-in timeout - no response received');

    isCheckInPending.value = false;
    missedCheckIns.value++;

    Get.back(); // Close dialog if still open

    // Send missed check-in
    _sendMissedCheckInResponse();
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
    final userModel = profileController.userModel.value;
    if (userModel == null) {
      dev.log('$_logTag User model is null, cannot send check-in');
      throw Exception('User information not available');
    }

    // Get current location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      dev.log('$_logTag Error getting location for check-in: $e');
      // Continue without location (will use 0,0)
    }

    final checkInData = {
      'userId': userModel.userId ?? '',
      'latitude': position?.latitude ?? 0.0,
      'longitude': position?.longitude ?? 0.0,
      'promptTime': (_currentPromptTime ?? DateTime.now()).toIso8601String(),
      'response': _getApiResponseString(status),
      'companyID': userModel.companyId ?? '',
      'siteId': userModel.siteId ?? '',
    };

    dev.log('$_logTag Sending check-in response: ${checkInData['response']}');

    if (connectivityController.isOffline.value) {
      // Queue for later
      _pendingCheckIns.add(checkInData);
      dev.log('$_logTag Check-in queued for later (offline)');
      return;
    }

    await _sendCheckInToApi(checkInData);
  }

  /// Send missed check-in response
  Future<void> _sendMissedCheckInResponse() async {
    try {
      await _sendCheckInResponse(CheckInStatus.pending);
    } catch (e) {
      dev.log('$_logTag Error sending missed check-in: $e');
    }
  }

  /// Send check-in data to API
  Future<void> _sendCheckInToApi(Map<String, dynamic> checkInData) async {
    try {
      isSubmittingCheckIn.value = true;

      final response = await _apiService.sendSafetyCheckIn(checkInData);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          dev.log(
            '$_logTag Check-in sent successfully. ID: ${responseData['id']}',
          );
        } else {
          throw Exception(
            'Server returned false status: ${responseData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } finally {
      isSubmittingCheckIn.value = false;
    }
  }

  /// Convert CheckInStatus to API response string
  String _getApiResponseString(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.allOk:
        return 'AllOK';
      case CheckInStatus.sos:
        return 'SOS';
      case CheckInStatus.ignored:
        return 'Ignore';
      case CheckInStatus.pending:
        return 'Missed'; // or 'NoResponse'
    }
  }

  /// Send SOS alert
  void _handleSosAlert() {
    Get.back(); // Close dialog
    _scheduleNextCheckIn();
    Get.snackbar(
      '🆘 SOS Alert Sent',
      'Emergency alert has been sent to admin and authorities',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.emergency, color: Colors.white),
      duration: const Duration(seconds: 5),
    );

    // Don't schedule next check-in for SOS - let admin handle
  }

  /// Helper methods
  Future<String> _getUserId() async {
    String? userId = await _storage.getUserId();
    if (userId == null || userId.isEmpty) {
      userId = profileController.userModel.value?.userId ?? '';
    }
    return userId;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Update configuration
  void updateConfiguration({int? intervalMinutes, int? responseMinutes}) {
    bool needsRestart = false;

    if (intervalMinutes != null &&
        intervalMinutes != checkInIntervalMinutes.value) {
      checkInIntervalMinutes.value = intervalMinutes;
      needsRestart = true;
      dev.log('$_logTag Updated check-in interval to $intervalMinutes minutes');
    }

    if (responseMinutes != null &&
        responseMinutes != responseWindowMinutes.value) {
      responseWindowMinutes.value = responseMinutes;
      dev.log('$_logTag Updated response window to $responseMinutes minutes');
    }

    // Restart service with new configuration
    if (needsRestart && isServiceActive.value) {
      dev.log('$_logTag Restarting SOS service with new configuration');
      stopService();
      startService();
    }
  }

  /// Get service status summary
  Map<String, dynamic> getServiceStatus() {
    return {
      'isActive': isServiceActive.value,
      'isPending': isCheckInPending.value,
      'isSubmitting': isSubmittingCheckIn.value,
      'checkInInterval': checkInIntervalMinutes.value,
      'responseWindow': responseWindowMinutes.value,
      'lastCheckIn': lastCheckInTime.value,
      'missedCount': missedCheckIns.value,
      'pendingCount': _pendingCheckIns.length,
      'nextCheckIn':
          isServiceActive.value
              ? DateTime.now()
                  .add(Duration(minutes: checkInIntervalMinutes.value))
                  .toIso8601String()
              : null,
    };
  }

  /// Force sync pending check-ins (for manual sync)
  Future<void> forceSyncPendingCheckIns() async {
    if (_pendingCheckIns.isEmpty) {
      Get.snackbar(
        'No Pending Check-ins',
        'All check-ins are already synced',
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (connectivityController.isOffline.value) {
      Get.snackbar(
        'No Internet Connection',
        'Please check your internet connection and try again',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    await _processPendingCheckIns();
  }
}

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

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _timerController, curve: Curves.linear));

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
                          _timerAnimation.value > 0.5
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time remaining: ${(_timerAnimation.value * sosService.responseWindowMinutes.value).ceil()} min',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                      onTap:
                          () => sosService.handleCheckInResponse(
                            CheckInStatus.allOk,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.emergency,
                      label: 'SOS',
                      color: Colors.red,
                      onTap:
                          () => sosService.handleCheckInResponse(
                            CheckInStatus.sos,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      () => sosService.handleCheckInResponse(
                        CheckInStatus.ignored,
                      ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Ignore',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
