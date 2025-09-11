import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';

class LiveTrackingService extends GetxController {
  static const String _logTag = '[LiveTrackingService]';
  
  // Dependencies
  final ApiGetServices _apiService = Get.find<ApiGetServices>();
  final ProfileController _profileController = Get.find<ProfileController>();
  final ConnectivityController _connectivityController = Get.find<ConnectivityController>();
  
  // Observables
  final RxBool isTrackingActive = false.obs;
  final RxBool isSubmittingLocation = false.obs;
  final Rx<Position?> currentLocation = Rx<Position?>(null);
  final RxString trackingStatus = 'Disabled'.obs;
  final RxInt failedAttempts = 0.obs;
  final RxInt successfulSends = 0.obs;
  final RxString lastUpdateTime = ''.obs;
  
  // Configuration from UserModel
  bool get liveTrackingEnabled => _profileController.userModel.value?.liveTrackingEnabled ?? false;
  int get trackingIntervalSeconds => _profileController.userModel.value?.liveTrackingIntervalSeconds ?? 300;
  
  // Private variables
  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionStream;
  List<Map<String, dynamic>> _pendingLocations = [];
  static const int _maxPendingLocations = 50;
  static const int _maxRetryAttempts = 3;
  
  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }
  
  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }
  
  void _initializeService() {
    log('$_logTag Initializing Live Tracking Service');
    
    // Listen to user model changes
    ever(_profileController.userModel, (UserModel? userModel) {
      if (userModel != null) {
        _handleUserModelUpdate(userModel);
      }
    });
    
    // Listen to connectivity changes
    ever(_connectivityController.isOffline, (bool isOffline) {
      if (!isOffline && _pendingLocations.isNotEmpty) {
        _processPendingLocations();
      }
    });
  }
  
  void _handleUserModelUpdate(UserModel userModel) {
    log('$_logTag User model updated - Live tracking enabled: ${userModel.liveTrackingEnabled}, Interval: ${userModel.liveTrackingIntervalSeconds}s');
    
    if (userModel.liveTrackingEnabled == true && userModel.clockStatus == true) {
      if (!isTrackingActive.value) {
        startTracking();
      } else {
        // Update tracking interval if changed
        _restartTrackingWithNewInterval();
      }
    } else {
      stopTracking();
    }
  }
  
  Future<bool> startTracking() async {
    if (isTrackingActive.value) {
      log('$_logTag Tracking already active');
      return true;
    }
    
    if (!liveTrackingEnabled) {
      log('$_logTag Live tracking is disabled for this user');
      trackingStatus.value = 'Disabled by configuration';
      return false;
    }
    
    try {
      // Check permissions
      if (!await _checkPermissions()) {
        trackingStatus.value = 'Permission denied';
        return false;
      }
      
      // Check if GPS is enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        trackingStatus.value = 'GPS disabled';
        _showLocationServiceDisabledDialog();
        return false;
      }
      
      isTrackingActive.value = true;
      trackingStatus.value = 'Starting...';
      failedAttempts.value = 0;
      successfulSends.value = 0;
      
      _startPeriodicTracking();
      
      log('$_logTag Live tracking started with interval: ${trackingIntervalSeconds}s');
      trackingStatus.value = 'Active';
      
      _showTrackingNotification('Live tracking started', Colors.green);
      
      return true;
      
    } catch (e) {
      log('$_logTag Error starting tracking: $e');
      trackingStatus.value = 'Error: $e';
      _showTrackingNotification('Failed to start tracking: $e', Colors.red);
      return false;
    }
  }
  
  void stopTracking() {
    if (!isTrackingActive.value) return;
    
    log('$_logTag Stopping live tracking');
    
    isTrackingActive.value = false;
    trackingStatus.value = 'Stopped';
    
    _trackingTimer?.cancel();
    _trackingTimer = null;
    
    _positionStream?.cancel();
    _positionStream = null;
    
    // Send any pending locations before stopping
    if (_pendingLocations.isNotEmpty && !_connectivityController.isOffline.value) {
      _processPendingLocations();
    }
    
    _showTrackingNotification('Live tracking stopped', Colors.orange);
    log('$_logTag Live tracking stopped successfully');
  }
  
  void _startPeriodicTracking() {
    _trackingTimer?.cancel();
    
    // Get initial location immediately
    _getCurrentLocationAndSend();
    
    // Start periodic updates
    _trackingTimer = Timer.periodic(
      Duration(seconds: trackingIntervalSeconds),
      (_) => _getCurrentLocationAndSend(),
    );
  }
  
  void _restartTrackingWithNewInterval() {
    if (isTrackingActive.value) {
      log('$_logTag Restarting tracking with new interval: ${trackingIntervalSeconds}s');
      _startPeriodicTracking();
    }
  }
  
  Future<void> _getCurrentLocationAndSend() async {
    if (!isTrackingActive.value) return;
    
    try {
      trackingStatus.value = 'Getting location...';
      
      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      currentLocation.value = position;
      lastUpdateTime.value = DateTime.now().toIso8601String();
      
      // Send location to server
      await _sendLocationToServer(position);
      
    } catch (e) {
      log('$_logTag Error getting location: $e');
      failedAttempts.value++;
      trackingStatus.value = 'Location error: $e';
      
      // If too many failures, stop tracking
      if (failedAttempts.value >= _maxRetryAttempts) {
        log('$_logTag Too many failed attempts, stopping tracking');
        stopTracking();
        _showTrackingNotification('Tracking stopped due to repeated errors', Colors.red);
      }
    }
  }
  
  Future<void> _sendLocationToServer(Position position) async {
    final userModel = _profileController.userModel.value;
    if (userModel == null) {
      log('$_logTag User model is null, cannot send location');
      return;
    }
    
    final locationData = {
      'userId': userModel.userId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'isClockedIn': userModel.clockStatus == true,
      'isClockedOut': userModel.clockStatus == false,
      'companyID': userModel.companyId,
      'siteId': userModel.siteId,
      // 'timestamp': DateTime.now().toIso8601String(),
      // 'accuracy': position.accuracy,
      // 'altitude': position.altitude,
      // 'heading': position.heading,
      // 'speed': position.speed,
    };
    
    // If offline, queue the location
    if (_connectivityController.isOffline.value) {
      _queueLocationData(locationData);
      trackingStatus.value = 'Offline - queued';
      return;
    }
    
    try {
      isSubmittingLocation.value = true;
      trackingStatus.value = 'Sending location...';
      
      final response = await _apiService.sendLiveLocation(locationData);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          successfulSends.value++;
          failedAttempts.value = 0; // Reset failed attempts on success
          trackingStatus.value = 'Active - Last sent: ${_formatTime(DateTime.now())}';
          
          log('$_logTag Location sent successfully. ID: ${responseData['id']}');
        } else {
          throw Exception('Server returned false status: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      log('$_logTag Error sending location: $e');
      failedAttempts.value++;
      trackingStatus.value = 'Send failed: ${e.toString().substring(0, 30)}...';
      
      // Queue the location for retry
      _queueLocationData(locationData);
      
      // Show error notification only for critical failures
      if (failedAttempts.value == 1) {
        _showTrackingNotification('Location send failed, will retry', Colors.orange);
      }
      
    } finally {
      isSubmittingLocation.value = false;
    }
  }
  
  void _queueLocationData(Map<String, dynamic> locationData) {
    _pendingLocations.add(locationData);
    
    // Limit queue size to prevent memory issues
    if (_pendingLocations.length > _maxPendingLocations) {
      _pendingLocations.removeAt(0);
      log('$_logTag Location queue full, removed oldest entry');
    }
    
    log('$_logTag Location queued. Queue size: ${_pendingLocations.length}');
  }
  
  Future<void> _processPendingLocations() async {
    if (_pendingLocations.isEmpty || _connectivityController.isOffline.value) {
      return;
    }
    
    log('$_logTag Processing ${_pendingLocations.length} pending locations');
    
    final locationsToSend = List<Map<String, dynamic>>.from(_pendingLocations);
    _pendingLocations.clear();
    
    int successCount = 0;
    int failCount = 0;
    
    for (final locationData in locationsToSend) {
      try {
        final response = await _apiService.sendLiveLocation(locationData);
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status'] == true) {
            successCount++;
          } else {
            failCount++;
            _pendingLocations.add(locationData); // Re-queue failed location
          }
        } else {
          failCount++;
          _pendingLocations.add(locationData); // Re-queue failed location
        }
        
        // Small delay between requests to avoid overwhelming server
        await Future.delayed(const Duration(milliseconds: 100));
        
      } catch (e) {
        failCount++;
        _pendingLocations.add(locationData); // Re-queue failed location
        log('$_logTag Error processing pending location: $e');
      }
    }
    
    if (successCount > 0 || failCount > 0) {
      _showTrackingNotification(
        'Synced $successCount locations${failCount > 0 ? ', $failCount failed' : ''}',
        failCount == 0 ? Colors.green : Colors.orange,
      );
    }
    
    log('$_logTag Processed pending locations: $successCount success, $failCount failed');
  }
  
  Future<bool> _checkPermissions() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog();
        return false;
      }
      
      if (permission == LocationPermission.denied) {
        _showTrackingNotification('Location permission denied', Colors.red);
        return false;
      }
      
      // For background tracking, we might need additional permissions
      // Check background location permission (Android 10+)
      if (await Permission.locationAlways.isDenied) {
        final status = await Permission.locationAlways.request();
        if (status.isDenied) {
          log('$_logTag Background location permission denied');
          // We can still track in foreground
        }
      }
      
      return true;
      
    } catch (e) {
      log('$_logTag Error checking permissions: $e');
      return false;
    }
  }
  
  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to track your position during work hours. '
          'Please enable location permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  
  void _showLocationServiceDisabledDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('GPS Disabled'),
        content: const Text(
          'Location services are disabled. Please enable GPS to start live tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Geolocator.openLocationSettings();
            },
            child: const Text('Enable GPS'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  
  void _showTrackingNotification(String message, Color color) {
    Get.snackbar(
      'Live Tracking',
      message,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      icon: Icon(
        color == Colors.green ? Icons.gps_fixed : 
        color == Colors.red ? Icons.gps_off : Icons.gps_not_fixed,
        color: Colors.white,
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
  
  // Manual trigger for testing
  void manualLocationUpdate() {
    if (isTrackingActive.value) {
      _getCurrentLocationAndSend();
    }
  }
  
  // Get tracking statistics
  Map<String, dynamic> getTrackingStats() {
    return {
      'isActive': isTrackingActive.value,
      'status': trackingStatus.value,
      'successfulSends': successfulSends.value,
      'failedAttempts': failedAttempts.value,
      'pendingLocations': _pendingLocations.length,
      'lastUpdate': lastUpdateTime.value,
      'intervalSeconds': trackingIntervalSeconds,
      'currentLocation': currentLocation.value != null ? {
        'latitude': currentLocation.value!.latitude,
        'longitude': currentLocation.value!.longitude,
        'accuracy': currentLocation.value!.accuracy,
      } : null,
    };
  }
}