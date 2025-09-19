import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:permission_handler/permission_handler.dart';
import 'package:security_guard/core/api/api_constants.dart';
import 'package:security_guard/data/services/api_get_service.dart';
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
  final RxString trackingStatus = 'Disabled'.obs;
  final RxInt failedAttempts = 0.obs;
  final RxInt successfulSends = 0.obs;
  final RxString lastUpdateTime = ''.obs;
  final Rx<bg.Location?> currentLocation = Rx<bg.Location?>(null);
  
  // Configuration
  bool get liveTrackingEnabled => _profileController.userModel.value?.liveTrackingEnabled ?? false;
  int get trackingIntervalSeconds => _profileController.userModel.value?.liveTrackingIntervalSeconds ?? 300;
  
  // Private variables
  List<Map<String, dynamic>> _pendingLocations = [];
  static const int _maxPendingLocations = 50;
  
  @override
  void onInit() {
    super.onInit();
    _initializeBackgroundGeolocation();
  }
  
  @override
  void onClose() {
    bg.BackgroundGeolocation.stop();
    bg.BackgroundGeolocation.removeListeners();
    super.onClose();
  }

  void _initializeBackgroundGeolocation() async {
    log('$_logTag Initializing Background Geolocation');
    
    // Configure the plugin
    bg.BackgroundGeolocation.onLocation(_onLocation);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.onActivityChange(_onActivityChange);
    bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    bg.BackgroundGeolocation.onHttp(_onHttp);
    
    // Configure the plugin
    bg.BackgroundGeolocation.ready(bg.Config(
      // Geolocation Config
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      
      // Activity Recognition
      stopTimeout: 1,
      
      // Application config
      debug: false, // Set to false for production
      logLevel: bg.Config.LOG_LEVEL_OFF,
      
      // HTTP / Persistence config
      url: '$BASE_URL/Tracking/live-tracking',
      httpRootProperty: '.',
      httpTimeout: 30000,
      
      // Background Task config
      enableHeadless: true,
      heartbeatInterval: trackingIntervalSeconds,
      
      // Geofencing (if needed)
      // geofenceProximityRadius: 1000,
      
      // iOS specific
      preventSuspend: true,
      disableElasticity: false,
      
      // Android specific
      notification: bg.Notification(
        title: "Live Tracking Active",
        text: "Tracking location for security purposes",
        color: "#2196F3",
        smallIcon: "drawable/ic_notification",
        largeIcon: "drawable/ic_launcher",
      ),
      foregroundService: true,
      
      // Auto sync
      autoSync: true,
      autoSyncThreshold: 5,
      
      // Battery optimization
      disableStopDetection: false,
      disableMotionActivityUpdates: false,
    ));
  }

  Future<bool> startTracking() async {
    if (isTrackingActive.value) {
      log('$_logTag Tracking already active');
      return true;
    }
    
    if (!liveTrackingEnabled) {
      log('$_logTag Live tracking disabled');
      trackingStatus.value = 'Disabled by configuration';
      return false;
    }
    
    try {
      trackingStatus.value = 'Starting...';
      
      // Update HTTP headers with auth token
      final deviceToken = LocalStorageService.instance.getDeviceToken();
      if (deviceToken != null) {
        bg.BackgroundGeolocation.setConfig(bg.Config(
          headers: {
            'Authorization': 'Bearer $deviceToken',
            'Content-Type': 'application/json',
          }
        ));
      }
      
      // Start the plugin
      bg.State state = await bg.BackgroundGeolocation.start();
      
      if (state.enabled) {
        isTrackingActive.value = true;
        trackingStatus.value = 'Active';
        failedAttempts.value = 0;
        
        log('$_logTag Background geolocation started successfully');
        
        _showTrackingNotification(
          'Live tracking started successfully!',
          backgroundColor: Colors.green,
          icon: Icons.gps_fixed,
        );
        
        return true;
      } else {
        trackingStatus.value = 'Failed to start';
        return false;
      }
      
    } catch (e) {
      log('$_logTag Error starting tracking: $e');
      trackingStatus.value = 'Error: $e';
      
      _showTrackingNotification(
        'Failed to start tracking: ${e.toString()}',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      
      return false;
    }
  }

  void stopTracking() async {
    if (!isTrackingActive.value) return;
    
    log('$_logTag Stopping live tracking');
    
    try {
      await bg.BackgroundGeolocation.stop();
      
      isTrackingActive.value = false;
      trackingStatus.value = 'Stopped';
      
      // Process any pending locations
      if (_pendingLocations.isNotEmpty && !_connectivityController.isOffline.value) {
        _processPendingLocations();
      }
      
      log('$_logTag Live tracking stopped successfully');
      
    } catch (e) {
      log('$_logTag Error stopping tracking: $e');
    }
  }

  // Location event handler
  void _onLocation(bg.Location location) {
    log('$_logTag Location received: ${location.coords.latitude}, ${location.coords.longitude}');
    
    currentLocation.value = location;
    lastUpdateTime.value = DateTime.now().toIso8601String();
    
    // The HTTP request is handled automatically by the plugin
    // but we can also manually send if needed
    _sendLocationToServer(location);
  }

  // Motion change event handler
  void _onMotionChange(bg.Location location) {
    log('$_logTag Motion changed: ${location.isMoving}');
    
    if (location.isMoving) {
      trackingStatus.value = 'Moving - Active tracking';
    } else {
      trackingStatus.value = 'Stationary - Reduced tracking';
    }
  }

  // Activity change event handler
  void _onActivityChange(bg.ActivityChangeEvent event) {
    log('$_logTag Activity changed: ${event.activity}');
  }

  // Provider change event handler
  void _onProviderChange(bg.ProviderChangeEvent event) {
    log('$_logTag Provider changed: GPS: ${event.gps}, Network: ${event.network}');
    
    if (!event.gps) {
      trackingStatus.value = 'GPS disabled';
      _showLocationServiceDisabledDialog();
    }
  }

  // Connectivity change event handler
  void _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    log('$_logTag Connectivity changed: ${event.connected}');
    
    if (event.connected) {
      trackingStatus.value = 'Online - Syncing';
      _processPendingLocations();
    } else {
      trackingStatus.value = 'Offline - Queuing';
    }
  }

  // HTTP response event handler
  void _onHttp(bg.HttpEvent event) {
    log('$_logTag HTTP Response: ${event.status}');
    
    if (event.status >= 200 && event.status < 300) {
      successfulSends.value++;
      failedAttempts.value = 0;
      trackingStatus.value = 'Active - Last sent: ${_formatTime(DateTime.now())}';
    } else {
      failedAttempts.value++;
      log('$_logTag HTTP Error: ${event.status} - ${event.responseText}');
    }
  }

  Future<void> _sendLocationToServer(bg.Location location) async {
    final userModel = _profileController.userModel.value;
    if (userModel == null) return;
    
    final locationData = {
      'userId': userModel.userId,
      'latitude': location.coords.latitude,
      'longitude': location.coords.longitude,
      'isClockedIn': userModel.clockStatus == true,
      'isClockedOut': userModel.clockStatus == false,
      'companyID': userModel.companyId,
      'siteId': userModel.siteId,
      'timestamp': location.timestamp,
      'accuracy': location.coords.accuracy,
      'speed': location.coords.speed,
      'heading': location.coords.heading,
      'altitude': location.coords.altitude,
    };
    
    // If offline, queue the location
    if (_connectivityController.isOffline.value) {
      _queueLocationData(locationData);
      return;
    }
    
    try {
      final response = await _apiService.sendLiveLocation(locationData);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          successfulSends.value++;
          failedAttempts.value = 0;
          log('$_logTag Location sent successfully');
        } else {
          throw Exception('Server returned false status: ${responseData['message']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      log('$_logTag Error sending location: $e');
      failedAttempts.value++;
      _queueLocationData(locationData);
    }
  }

  void _queueLocationData(Map<String, dynamic> locationData) {
    _pendingLocations.add(locationData);
    
    if (_pendingLocations.length > _maxPendingLocations) {
      _pendingLocations.removeAt(0);
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
    
    for (final locationData in locationsToSend) {
      try {
        final response = await _apiService.sendLiveLocation(locationData);
        
        if (response.statusCode != 200) {
          _pendingLocations.add(locationData);
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
      } catch (e) {
        _pendingLocations.add(locationData);
        log('$_logTag Error processing pending location: $e');
      }
    }
  }

  // UI Helper methods
  void _showTrackingNotification(String message, {
    Color? backgroundColor,
    IconData? icon,
  }) {
    Get.snackbar(
      'Live Tracking',
      message,
      backgroundColor: backgroundColor ?? Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: Icon(icon ?? Icons.info, color: Colors.white),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void _showLocationServiceDisabledDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('GPS Disabled'),
        content: const Text('Location services are disabled. Please enable GPS to continue tracking.'),
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
            child: const Text('Enable GPS'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }

  // Public methods
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
        'latitude': currentLocation.value!.coords.latitude,
        'longitude': currentLocation.value!.coords.longitude,
        'accuracy': currentLocation.value!.coords.accuracy,
      } : null,
    };
  }

  Future<void> forceSyncPendingLocations() async {
    if (_pendingLocations.isNotEmpty) {
      await _processPendingLocations();
    }
  }
}