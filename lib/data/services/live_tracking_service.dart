// (same imports as you had)
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' show atan2, cos, pi, sin, sqrt;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:permission_handler/permission_handler.dart';
import 'package:security_guard/core/api/api_constants.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:geolocator/geolocator.dart';

class LiveTrackingService extends GetxController {
  static const String _logTag = '[LiveTrackingService]';

  // Dependencies
  final ApiGetServices _apiService = Get.find<ApiGetServices>();
  final ProfileController _profileController = Get.find<ProfileController>();
  final ConnectivityController _connectivityController =
      Get.find<ConnectivityController>();

  // Observables
  final RxBool isTrackingActive = false.obs;
  final RxString trackingStatus = 'Disabled'.obs;
  final RxInt failedAttempts = 0.obs;
  final RxInt successfulSends = 0.obs;
  final RxString lastUpdateTime = ''.obs;
  final Rx<bg.Location?> currentLocation = Rx<bg.Location?>(null);

  // Configuration getters
  bool get liveTrackingEnabled =>
      _profileController.userModel.value?.liveTrackingEnabled ?? false;
  int get trackingIntervalSeconds =>
      _profileController.userModel.value?.liveTrackingIntervalSeconds ?? 300;

  Timer? _watchdog;
  int _restartAttempts = 0;

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(Duration(minutes: 1), (t) async {
      try {
        final state = await bg.BackgroundGeolocation.state;
        if (!liveTrackingEnabled) {
          return; // Don't restart if tracking is disabled
        }
        if (liveTrackingEnabled && !state.enabled) {
          if (_restartAttempts < 6) {
            _restartAttempts++;
            log(
              'Watchdog: plugin not enabled -> attempting restart (#$_restartAttempts)',
            );
            await startTracking();
          } else {
            log('Watchdog: reached restart cap, notifying user');
            _showTrackingNotification(
              'Unable to auto-restart tracking — please open app and allow permissions.',
              backgroundColor: Colors.orange,
              icon: Icons.warning,
            );
          }
        } else if (state.enabled) {
          _restartAttempts = 0;
        }
      } catch (e) {
        log('Watchdog error: $e');
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    _initializeBackgroundGeolocation();
  }

  @override
  void onClose() {
    _watchdog?.cancel();
    bg.BackgroundGeolocation.removeListeners();
    super.onClose();
  }

  /// --------------------
  /// Initialize plugin (AWAIT ready and apply HTTP config)
  /// --------------------
  void _initializeBackgroundGeolocation() async {
    log('$_logTag Initializing Background Geolocation (plugin-http flow)');

    // Register event handlers
    bg.BackgroundGeolocation.onLocation(_onLocation);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.onActivityChange(_onActivityChange);
    bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    bg.BackgroundGeolocation.onHttp(_onHttp);
    bg.BackgroundGeolocation.onHeartbeat(_onHeartbeat);

    bg.BackgroundGeolocation.onHttp((bg.HttpEvent event) {
      log(
        "📡 HTTP response code: ${event.status} success: ${event.success} response: ${event.responseText}",
      );
    });

    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      log("📡 Provider change: enabled=${event.enabled} gps=${event.gps}");
    });

    bg.BackgroundGeolocation.onConnectivityChange((
      bg.ConnectivityChangeEvent event,
    ) {
      log("🌐 Connectivity change: connected=${event.connected}");
    });

    final initialCfg = bg.Config(
      desiredAccuracy:
          bg.Config.DESIRED_ACCURACY_HIGH, // navigation is fine — high accuracy
      allowIdenticalLocations: true,
      distanceFilter: 0.0, // send even if distance == 0
      disableStopDetection:
          true, // prevent SDK from auto-stopping when stationary
      stopTimeout: 999999, // effectively disable stop-timeouts
      isMoving: true, // hint plugin to stay 'moving' state
      locationUpdateInterval: 30000, // 30s updates; tune for battery vs freshness
      fastestLocationUpdateInterval: 5000,
      heartbeatInterval: 60, // keep heartbeat to persist positions periodically
      preventSuspend: true, // ask system to avoid suspension (best-effort)
      enableHeadless: true,
      stopOnTerminate: false, // keep running after app killed
      startOnBoot: true, // start after reboot
      foregroundService: true,
      notification: bg.Notification(
        title: "Live Tracking Active",
        text: "Location tracking is running",
        priority:
            bg.Config.NOTIFICATION_PRIORITY_MIN, // or NOTIFICATION_PRIORITY_LOW
        channelName: "Background Location (Silent)",
        color: "#2196F3",
      ),
      debug: false, // 👈 CHANGE THIS FROM true TO false
      logLevel: bg.Config.LOG_LEVEL_OFF, // 👈 ALSO DISABLE VERBOSE LOGGING
      url: '${BASE_URL}Tracking/live-tracking',
      autoSync: true,
      autoSyncThreshold: 1,
      batchSync: false,
      maxBatchSize: 1,
      // ensure plugin requests always authorization when needed
      locationAuthorizationRequest:
          'Always', // plugin-specific string; keep 'Always' behavior
    );

    try {
      final bg.State state = await bg.BackgroundGeolocation.ready(initialCfg);
      log(
        '$_logTag BackgroundGeolocation.ready -> enabled=${state.enabled} url=${state.url}',
      );

      // Apply HTTP headers & params (token + user info)
      final deviceToken = LocalStorageService.instance.getDeviceToken();
      final userModel = _profileController.userModel.value;
      await _applyPluginHttpConfig(
        deviceToken: deviceToken,
        userModel: userModel,
      );
    } catch (e) {
      log('$_logTag ready() failed: $e');
    }
  }

  /// Apply headers and params (user + token) to plugin's HTTP layer.
  /// These `params` will be merged into every HTTP POST payload by the SDK.
  Future<void> _applyPluginHttpConfig({
    String? deviceToken,
    UserModel? userModel,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (deviceToken != null && deviceToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $deviceToken';
      }

      final params = <String, dynamic>{};
      if (userModel != null) {
        params['userId'] = userModel.userId;
        params['companyID'] = userModel.companyId;
        params['siteId'] = userModel.siteId;

        params['isClockedIn'] = userModel.clockStatus == true;
        params['isClockedOut'] = !userModel.clockStatus;
      }

      // Important: await setConfig so plugin will use these headers/params immediately
      await bg.BackgroundGeolocation.setConfig(
        bg.Config(
          url: '${BASE_URL}Tracking/live-tracking',
          headers: headers,
          params: params,
          autoSync: true,
          autoSyncThreshold: 1, // keep low for testing
          batchSync: false,
          maxBatchSize: 1,
          // httpRootProperty: '',
        ),
      );

      log(
        '$_logTag Applied HTTP config -> url=${BASE_URL}Tracking/live-tracking headers=${headers.keys.toList()} params=${params.keys.toList()}',
      );
    } catch (e) {
      log('$_logTag Error applying HTTP config: $e');
    }
  }

  /// Public start: ensures HTTP config is set, then starts the plugin
  Future<bool> startTracking() async {
    if (isTrackingActive.value) {
      log('$_logTag Tracking already active');
      return true;
    }

    if (!liveTrackingEnabled) {
      log('$_logTag Live tracking disabled by configuration');
      trackingStatus.value = 'Disabled by configuration';
      return false;
    }

    if (!await _checkLocationPermissions()) {
      trackingStatus.value = 'Location permission denied';
      return false;
    }

    try {
      trackingStatus.value = 'Starting...';

      // Apply fresh headers/params before start
      final deviceToken = LocalStorageService.instance.getDeviceToken();
      final userModel = _profileController.userModel.value;
      await _applyPluginHttpConfig(
        deviceToken: deviceToken,
        userModel: userModel,
      );

      await Future.delayed(Duration(milliseconds: 100));
      // Start the plugin
      final state = await bg.BackgroundGeolocation.start();
      _startWatchdog();
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

  Future<bool> _checkLocationPermissions() async {
    try {
      final permission = await Permission.locationAlways.status;
      if (permission != PermissionStatus.granted) {
        final result = await Permission.locationAlways.request();
        return result == PermissionStatus.granted;
      }
      return true;
    } catch (e) {
      log('Permission check error: $e');
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

      log('$_logTag Live tracking stopped successfully');
    } catch (e) {
      log('$_logTag Error stopping tracking: $e');
    }
  }

  void _onHeartbeat(bg.HeartbeatEvent event) async {
    try {
      // Persist a heartbeat location so autoSync can pick it up (optional)
      final loc = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 2,
        timeout: 10,
        persist: true,
        extras: {'event': 'heartbeat', 'source': 'service'},
      );
      log(
        '$_logTag [heartbeat] persisted ${loc.coords.latitude}, ${loc.coords.longitude}',
      );
    } catch (e) {
      log('$_logTag [heartbeat] error: $e');
    }
  }

  // Location event handler — DO NOT manually send HTTP here when using plugin HTTP.
  void _onLocation(bg.Location location) {
    // Filter out inaccurate locations (relaxed threshold for reliability)
    if (location.coords.accuracy != null && location.coords.accuracy! > 200) {
      log(
        '$_logTag Location rejected due to poor accuracy: ${location.coords.accuracy}m',
      );
      return;
    }

    // Additional validation for stationary detection
    if (currentLocation.value != null) {
      double distance = _calculateDistance(
        currentLocation.value!.coords.latitude,
        currentLocation.value!.coords.longitude,
        location.coords.latitude,
        location.coords.longitude,
      );

      // Log questionable jumps but do not silently drop everything
      if (distance > 1000 && !location.isMoving) {
        log(
          '$_logTag Large jump detected (${distance}m) while stationary; keeping location but logging.',
        );
      }
    }

    log(
      '$_logTag Location accepted (persisted by plugin): ${location.coords.latitude}, ${location.coords.longitude}, accuracy: ${location.coords.accuracy}m',
    );

    // Update local state for UI
    currentLocation.value = location;
    lastUpdateTime.value = DateTime.now().toIso8601String();

    // IMPORTANT: Do NOT call your HTTP client here. The SDK will persist and auto-sync.
    // If you still need to send extra per-location fields that change rapidly, update
    // bg.Config.params via setConfig elsewhere (e.g., when user status flips).
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _onMotionChange(bg.Location location) {
    log('$_logTag Motion changed: ${location.isMoving}');
    trackingStatus.value =
        location.isMoving
            ? 'Moving - Active tracking'
            : 'Stationary - Reduced tracking';
  }

  void _onActivityChange(bg.ActivityChangeEvent event) {
    log('$_logTag Activity changed: ${event.activity}');
  }

  void _onProviderChange(bg.ProviderChangeEvent event) {
    log(
      '$_logTag Provider changed: GPS: ${event.gps}, Network: ${event.network}',
    );
    if (!event.gps) {
      trackingStatus.value = 'GPS disabled';
      _showLocationServiceDisabledDialog();
    }
  }

  void _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    log('$_logTag Connectivity changed: ${event.connected}');
    if (event.connected) {
      trackingStatus.value = 'Online - Syncing';
      // SDK will automatically sync when connectivity is restored.
    } else {
      trackingStatus.value = 'Offline - Queuing (plugin DB)';
    }
  }

  // HTTP response from plugin's HTTP layer
  void _onHttp(bg.HttpEvent event) {
    // log('$_logTag HTTP Request URL: ${event.url}');
    // log('$_logTag HTTP Request Method: ${event.method}');
    // log('$_logTag HTTP Request Body: ${event.requestData}'); // This shows what was sent
    log(
      '$_logTag HTTP Response: status=${event.status} response=${event.responseText}',
    );
    log('$_logTag HTTP Response Text: ${event.responseText}');
    if (event.status >= 200 && event.status < 300) {
      successfulSends.value++;
      failedAttempts.value = 0;
      trackingStatus.value =
          'Active - Last sent: ${_formatTime(DateTime.now())}';
    } else {
      failedAttempts.value++;
      log('$_logTag HTTP Error: ${event.status} - ${event.responseText}');
    }
  }

  /// Force the plugin to upload all stored locations right now.
  Future<void> forceSyncPendingLocations() async {
    try {
      final result = await bg.BackgroundGeolocation.sync();
      log('$_logTag forceSync result length=${result?.length ?? 0}');
    } catch (e) {
      log('$_logTag forceSync error: $e');
    }
  }

  // UI Helper methods (unchanged)
  void _showTrackingNotification(
    String message, {
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
        content: const Text(
          'Location services are disabled. This app tracks your location in the background to ensure you are within your assigned patrol area.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              Geolocator.openLocationSettings();
            },
            child: const Text('Enable GPS'),
          ),
        ],
      ),
    );
  }

  Future<void> reset() async {
    print('[LiveTrackingService] Resetting tracking service');
    await bg.BackgroundGeolocation.stop();
    await bg.BackgroundGeolocation.removeListeners();
    isTrackingActive.value = false;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  // Public method returning current stats
  Map<String, dynamic> getTrackingStats() {
    return {
      'isActive': isTrackingActive.value,
      'status': trackingStatus.value,
      'successfulSends': successfulSends.value,
      'failedAttempts': failedAttempts.value,
      'lastUpdate': lastUpdateTime.value,
      'intervalSeconds': trackingIntervalSeconds,
      'currentLocation':
          currentLocation.value != null
              ? {
                'latitude': currentLocation.value!.coords.latitude,
                'longitude': currentLocation.value!.coords.longitude,
                'accuracy': currentLocation.value!.coords.accuracy,
              }
              : null,
    };
  }
}
