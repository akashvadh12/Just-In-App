import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:security_guard/core/api/api_constants.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/data/services/backgroud_location_service.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
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
  final RxBool isBackgroundTrackingEnabled = false.obs;
  final RxBool backgroundServiceRunning = false.obs;
  
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
  
  void _initializeService() async {
    log('$_logTag Initializing Live Tracking Service with Background Support');
    
    // Initialize background service
    await BackgroundLocationService.initializeService();
    
    // Check if background service is already running
    backgroundServiceRunning.value = await BackgroundLocationService.isBackgroundTrackingRunning();
    
    // Listen to background service updates
    _listenToBackgroundService();
    
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
  
  void _listenToBackgroundService() {
    final service = FlutterBackgroundService();
    
    service.on('locationUpdate').listen((event) {
      log('$_logTag Received background location update: $event');
      
      if (event != null) {
        // Update UI with background location data
        if (event['success'] == true) {
          successfulSends.value++;
          failedAttempts.value = 0;
          lastUpdateTime.value = event['timestamp'] ?? '';
          trackingStatus.value = 'Background active';
        } else {
          failedAttempts.value++;
        }
        
        // Update current location if we received coordinates
        if (event['latitude'] != null && event['longitude'] != null) {
          // Create a position object for display purposes
          // Note: We can't create a full Position object without all required fields
          // So we'll just update our tracking info
          lastUpdateTime.value = event['timestamp'] ?? DateTime.now().toIso8601String();
        }
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
  
  Future<bool> startTracking({bool enableBackground = true}) async {
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
      // Check permissions first
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
      
      // Start foreground tracking
      _startPeriodicTracking();
      
      // Start background tracking if enabled and permissions allow
      if (enableBackground && isBackgroundTrackingEnabled.value) {
        await _startBackgroundTracking();
      }
      
      log('$_logTag Live tracking started with interval: ${trackingIntervalSeconds}s');
      trackingStatus.value = isBackgroundTrackingEnabled.value ? 'Active (Background enabled)' : 'Active (Foreground only)';
      
      _showTrackingNotification('Live tracking started', Colors.green);
      
      return true;
      
    } catch (e) {
      log('$_logTag Error starting tracking: $e');
      trackingStatus.value = 'Error: $e';
      _showTrackingNotification('Failed to start tracking: $e', Colors.red);
      return false;
    }
  }
  
  Future<void> _startBackgroundTracking() async {
    final userModel = _profileController.userModel.value;
    if (userModel == null) {
      log('$_logTag Cannot start background tracking: user model is null');
      return;
    }
    
    try {
      // Get API base URL from your API service
      // You'll need to expose this from your ApiGetServices class
       final deviceToken = LocalStorageService.instance.getDeviceToken();
      final String apiBaseUrl = BASE_URL; // Add this getter to your API service
      final String? authToken = deviceToken; // Add this getter to your API service
      
      await BackgroundLocationService.startBackgroundTracking(
        userId: userModel.userId ?? '',
        companyId: userModel.companyId ?? '',
        siteId: userModel.siteId ?? '',
        isClocked: userModel.clockStatus == true,
        trackingInterval: trackingIntervalSeconds,
        apiBaseUrl: apiBaseUrl,
        authToken: authToken,
      );
      
      backgroundServiceRunning.value = true;
      log('$_logTag Background tracking started successfully');
      
    } catch (e) {
      log('$_logTag Error starting background tracking: $e');
      _showTrackingNotification('Background tracking failed to start', Colors.orange);
    }
  }
  
  void stopTracking() async {
    if (!isTrackingActive.value) return;
    
    log('$_logTag Stopping live tracking');
    
    isTrackingActive.value = false;
    trackingStatus.value = 'Stopped';
    
    // Stop foreground tracking
    _trackingTimer?.cancel();
    _trackingTimer = null;
    
    _positionStream?.cancel();
    _positionStream = null;
    
    // Stop background tracking
    await BackgroundLocationService.stopBackgroundTracking();
    backgroundServiceRunning.value = false;
    
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
      Duration(seconds: 60),
      (_) => _getCurrentLocationAndSend(),
    );
  }
  
  void _restartTrackingWithNewInterval() async {
    if (isTrackingActive.value) {
      log('$_logTag Restarting tracking with new interval: ${trackingIntervalSeconds}s');
      
      // Update foreground tracking
      _startPeriodicTracking();
      
      // Update background tracking configuration
      final userModel = _profileController.userModel.value;
      if (userModel != null && backgroundServiceRunning.value) {
        await BackgroundLocationService.updateBackgroundConfig(
          isClocked: userModel.clockStatus == true,
          trackingInterval: trackingIntervalSeconds,
        );
      }
    }
  }
  Future<void> _getCurrentLocationAndSend() async {
  if (!isTrackingActive.value) return;
  
  try {
    trackingStatus.value = 'Getting location...';
    
    // Different settings for foreground vs background
    LocationAccuracy accuracy = LocationAccuracy.high;
    Duration timeout = const Duration(seconds: 15);
    
    // Check if app is in background and adjust settings
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.detached) {
      accuracy = LocationAccuracy.medium; // Less demanding
      timeout = const Duration(seconds: 30); // More time
    }
    
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      timeLimit: timeout,
    );
    
    currentLocation.value = position;
    lastUpdateTime.value = DateTime.now().toIso8601String();
    
    await _sendLocationToServer(position);
    
  } catch (e) {
    log('$_logTag Error getting location: $e');
    
    // Handle timeout specifically
    if (e is TimeoutException) {
      // await _handleLocationTimeout();
    } else {
      failedAttempts.value++;
      trackingStatus.value = 'Location error: $e';
      
      if (failedAttempts.value >= _maxRetryAttempts) {
        log('$_logTag Too many failed attempts, stopping tracking');
        stopTracking();
        _showTrackingNotification('Tracking stopped due to repeated errors', Colors.red);
      }
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
          failedAttempts.value = 0;
          trackingStatus.value = backgroundServiceRunning.value ? 
            'Active (Background enabled) - Last sent: ${_formatTime(DateTime.now())}' :
            'Active - Last sent: ${_formatTime(DateTime.now())}';
          
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
            _pendingLocations.add(locationData);
          }
        } else {
          failCount++;
          _pendingLocations.add(locationData);
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
      } catch (e) {
        failCount++;
        _pendingLocations.add(locationData);
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
      
      // For background tracking, we need "always" location permission
      if (await Permission.locationAlways.isDenied) {
        _showBackgroundPermissionDialog();
        final status = await Permission.locationAlways.request();
        
        if (status.isGranted) {
          isBackgroundTrackingEnabled.value = true;
          log('$_logTag Background location permission granted');
        } else if (status.isPermanentlyDenied) {
          _showBackgroundPermissionDeniedDialog();
          isBackgroundTrackingEnabled.value = false;
        } else {
          isBackgroundTrackingEnabled.value = false;
          log('$_logTag Background location permission denied');
        }
      } else if (await Permission.locationAlways.isGranted) {
        isBackgroundTrackingEnabled.value = true;
      }
      
      // Check notification permission for foreground service
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
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
  
  void _showBackgroundPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Background Location Permission'),
        content: const Text(
          'To continue tracking your location when the app is closed or minimized, '
          'please allow "All the time" location access in the next screen.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              isBackgroundTrackingEnabled.value = false;
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  
  void _showBackgroundPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Background Tracking Unavailable'),
        content: const Text(
          'Background location permission was denied. The app will only track your location '
          'when it\'s open. You can enable background tracking later in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
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
  
  // Public methods for manual control
  void manualLocationUpdate() {
    if (isTrackingActive.value) {
      _getCurrentLocationAndSend();
    }
  }
  
  Future<void> toggleBackgroundTracking(bool enable) async {
    if (enable && !isBackgroundTrackingEnabled.value) {
      // Check background permission first
      if (await Permission.locationAlways.request().isGranted) {
        isBackgroundTrackingEnabled.value = true;
        if (isTrackingActive.value) {
          await _startBackgroundTracking();
        }
        _showTrackingNotification('Background tracking enabled', Colors.green);
      } else {
        _showBackgroundPermissionDeniedDialog();
      }
    } else if (!enable && isBackgroundTrackingEnabled.value) {
      isBackgroundTrackingEnabled.value = false;
      await BackgroundLocationService.stopBackgroundTracking();
      backgroundServiceRunning.value = false;
      _showTrackingNotification('Background tracking disabled', Colors.orange);
    }
  }
  
  // Get comprehensive tracking statistics
  Map<String, dynamic> getTrackingStats() {
    return {
      'isActive': isTrackingActive.value,
      'status': trackingStatus.value,
      'successfulSends': successfulSends.value,
      'failedAttempts': failedAttempts.value,
      'pendingLocations': _pendingLocations.length,
      'lastUpdate': lastUpdateTime.value,
      'intervalSeconds': trackingIntervalSeconds,
      'backgroundEnabled': isBackgroundTrackingEnabled.value,
      'backgroundRunning': backgroundServiceRunning.value,
      'currentLocation': currentLocation.value != null ? {
        'latitude': currentLocation.value!.latitude,
        'longitude': currentLocation.value!.longitude,
        'accuracy': currentLocation.value!.accuracy,
      } : null,
    };
  }
  
  // Force sync pending locations
  Future<void> forceSyncPendingLocations() async {
    if (_pendingLocations.isNotEmpty) {
      await _processPendingLocations();
    }
  }
  
  // Check and request all required permissions at once
  Future<bool> requestAllPermissions() async {
    return await _checkPermissions();
  }
  
  // Method to handle app lifecycle changes
  void handleAppLifecycleState(AppLifecycleState state) {
    log('$_logTag App lifecycle state changed to: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        if (isTrackingActive.value) {
          // Check if background service is still running
          BackgroundLocationService.isBackgroundTrackingRunning().then((isRunning) {
            backgroundServiceRunning.value = isRunning;
            if (isRunning && !isBackgroundTrackingEnabled.value) {
              // Background service is running but we lost the state, restore it
              isBackgroundTrackingEnabled.value = true;
            }
          });
        }
        break;
      case AppLifecycleState.paused:
        // App went to background
        if (isTrackingActive.value && !isBackgroundTrackingEnabled.value) {
          log('$_logTag App paused but background tracking not enabled');
        }
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        log('$_logTag App is being terminated');
        break;
      default:
        break;
    }
  }
  
  // Method to check system battery optimization settings
  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      // This would require a native plugin or custom implementation
      // For now, we'll return true and advise users manually
      return true;
    } catch (e) {
      log('$_logTag Error checking battery optimization: $e');
      return false;
    }
  }
  
  // Method to show battery optimization warning
  void showBatteryOptimizationWarning() {
    Get.dialog(
      AlertDialog(
        title: const Text('Battery Optimization'),
        content: const Text(
          'For reliable background location tracking, please disable battery optimization for this app in your device settings.\n\n'
          'Go to Settings > Apps > [Your App Name] > Battery > Battery Optimization > Don\'t optimize',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // On Android, you could try to open battery optimization settings
              // This would require additional platform-specific code
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  // Method to validate tracking configuration
  bool validateTrackingConfiguration() {
    final userModel = _profileController.userModel.value;
    
    if (userModel == null) {
      log('$_logTag Validation failed: User model is null');
      return false;
    }
    
    if (userModel.userId == null || userModel.userId!.isEmpty) {
      log('$_logTag Validation failed: User ID is missing');
      return false;
    }
    
    if (trackingIntervalSeconds < 30) {
      log('$_logTag Validation failed: Tracking interval too short (${trackingIntervalSeconds}s)');
      return false;
    }
    
    if (trackingIntervalSeconds > 3600) {
      log('$_logTag Validation failed: Tracking interval too long (${trackingIntervalSeconds}s)');
      return false;
    }
    
    return true;
  }
  
  // Method to get detailed location info
  Future<Map<String, dynamic>?> getDetailedLocationInfo() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'timestamp': position.timestamp.toIso8601String(),
        'isMocked': position.isMocked,
      };
      
    } catch (e) {
      log('$_logTag Error getting detailed location info: $e');
      return null;
    }
  }
  
  // Method to export tracking logs for debugging
  Map<String, dynamic> exportTrackingLogs() {
    return {
      'trackingStats': getTrackingStats(),
      'configuration': {
        'liveTrackingEnabled': liveTrackingEnabled,
        'trackingIntervalSeconds': trackingIntervalSeconds,
        'maxPendingLocations': _maxPendingLocations,
        'maxRetryAttempts': _maxRetryAttempts,
      },
      'userInfo': {
        'userId': _profileController.userModel.value?.userId,
        'companyId': _profileController.userModel.value?.companyId,
        'siteId': _profileController.userModel.value?.siteId,
        'clockStatus': _profileController.userModel.value?.clockStatus,
      },
      'systemInfo': {
        'isConnected': !_connectivityController.isOffline.value,
        'pendingLocationsCount': _pendingLocations.length,
      },
      'exportTime': DateTime.now().toIso8601String(),
    };
  }
}