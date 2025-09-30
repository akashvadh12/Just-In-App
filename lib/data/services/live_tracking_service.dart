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

  final RxBool isInitialized = false.obs;
  final RxBool isInitializing = false.obs;

  Timer? _watchdog;
  int _restartAttempts = 0;

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(Duration(minutes: 3), (t) async {
      try {
        final state = await bg.BackgroundGeolocation.state;

        // ✅ CRITICAL: Check user status BEFORE restarting
        final userModel = _profileController.userModel.value;
        final isClockedIn = userModel?.clockStatus == true;
        final trackingEnabled = userModel?.liveTrackingEnabled == true;

        if (!isClockedIn || !trackingEnabled) {
          log(
            'Watchdog: User clocked out or tracking disabled - NOT restarting',
          );
          return; // Exit early, don't restart
        }

        // Rest of watchdog logic...
        if (!state.enabled) {
          if (_restartAttempts < 6) {
            _restartAttempts++;
            log('Watchdog: attempting restart (#$_restartAttempts)');
            await startTracking();
          }
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

  /// Update tracking interval when userModel changes
  Future<void> updateTrackingInterval() async {
    if (!isInitialized.value) {
      log('$_logTag Cannot update interval - not initialized');
      return;
    }

    final intervalSeconds = trackingIntervalSeconds;

    log('$_logTag Updating tracking interval to $intervalSeconds seconds');

    try {
      await bg.BackgroundGeolocation.setConfig(
        bg.Config(
          locationUpdateInterval: intervalSeconds * 1000,
          fastestLocationUpdateInterval: intervalSeconds * 1000,
        ),
      );

      log(
        '$_logTag ✅ Tracking interval updated successfully to $intervalSeconds seconds',
      );
    } catch (e) {
      log('$_logTag ❌ Error updating tracking interval: $e');
    }
  }

  /// --------------------
  /// Initialize plugin (AWAIT ready and apply HTTP config)
  /// --------------------
  void _initializeBackgroundGeolocation() async {
    if (isInitializing.value || isInitialized.value) return;

    isInitializing.value = true;
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
      locationUpdateInterval:
          trackingIntervalSeconds *
          1000, // 30s updates; tune for battery vs freshness
      fastestLocationUpdateInterval: trackingIntervalSeconds * 1000,
      // heartbeatInterval: 60, // keep heartbeat to persist positions periodically
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

      isInitialized.value = true;
      isInitializing.value = false;
    } catch (e) {
      isInitializing.value = false;
      isInitialized.value = false;

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

    try {
      trackingStatus.value = 'Starting...';

      // ✅ STEP 1: Check device GPS/Location services
      final locationServiceEnabled = await _isLocationServiceEnabled();
      if (!locationServiceEnabled) {
        trackingStatus.value = 'GPS disabled on device';
        log('$_logTag Cannot start - device location services disabled');
        return false;
      }

      // ✅ STEP 2: Request app permissions
      final hasPermissions = await _requestLocationPermissions();
      if (!hasPermissions) {
        trackingStatus.value = 'Permission denied';
        log('$_logTag Cannot start - app permissions denied');
        return false;
      }

      // ✅ STEP 3: Wait for plugin initialization
      if (!isInitialized.value) {
        log('$_logTag Waiting for initialization...');
        int attempts = 0;
        while (!isInitialized.value && attempts < 60) {
          await Future.delayed(Duration(milliseconds: 500));
          attempts++;
        }

        if (!isInitialized.value) {
          trackingStatus.value = 'Initialization timeout';
          log('$_logTag Initialization timeout after 30 seconds');
          return false;
        }
      }

      log(
        '📍 UserModel interval: ${_profileController.userModel.value?.liveTrackingIntervalSeconds}',
      );
      log('📍 Getter returns: $trackingIntervalSeconds');
      await updateTrackingInterval();

      // ✅ STEP 4: Apply fresh HTTP config
      final deviceToken = LocalStorageService.instance.getDeviceToken();
      final userModel = _profileController.userModel.value;
      await _applyPluginHttpConfig(
        deviceToken: deviceToken,
        userModel: userModel,
      );

      // ✅ STEP 5: Check current plugin state
      final currentState = await bg.BackgroundGeolocation.state;
      log('$_logTag Current plugin state: enabled=${currentState.enabled}');

      if (currentState.enabled) {
        log('$_logTag Plugin already enabled, no need to start');
        isTrackingActive.value = true;
        trackingStatus.value = 'Active';
        _startWatchdog();

        // ✅ NOW you can call changePace since plugin is already started
        await bg.BackgroundGeolocation.changePace(true);

        _showTrackingNotification(
          'Live tracking already active',
          backgroundColor: Colors.green,
          icon: Icons.gps_fixed,
        );

        return true;
      }

      // ✅ STEP 6: Start tracking (REMOVED changePace BEFORE start)
      log('$_logTag Starting plugin...');

      // 🚨 CRITICAL FIX: Call start() FIRST, changePace() AFTER
      final newState = await bg.BackgroundGeolocation.start();

      log('$_logTag After start(): enabled=${newState.enabled}');

      if (newState.enabled) {
        // ✅ NOW call changePace AFTER successful start
        // await bg.BackgroundGeolocation.changePace(true);

        isTrackingActive.value = true;
        trackingStatus.value = 'Active';
        failedAttempts.value = 0;
        _startWatchdog();

        log('$_logTag ✅ Tracking started successfully');

        _showTrackingNotification(
          'Live tracking started successfully!',
          backgroundColor: Colors.green,
          icon: Icons.gps_fixed,
        );

        return true;
      } else {
        trackingStatus.value = 'Failed to enable plugin';
        log('$_logTag ❌ Plugin not enabled after start()');

        _showTrackingNotification(
          'Could not enable location tracking. Please check your GPS settings.',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );

        return false;
      }
    } catch (e) {
      log('$_logTag ❌ Error starting tracking: $e');
      trackingStatus.value = 'Error: $e';

      String errorMessage = 'Failed to start tracking';

      if (e.toString().contains('disabled')) {
        errorMessage =
            'Location services are disabled. Please enable GPS in device settings.';
        await Future.delayed(Duration(seconds: 1));
        await Geolocator.openLocationSettings();
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      _showTrackingNotification(
        errorMessage,
        backgroundColor: Colors.red,
        icon: Icons.error,
      );

      return false;
    }
  }

  /// Check if device location services (GPS) are enabled
  Future<bool> _isLocationServiceEnabled() async {
    try {
      // Check using Geolocator
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        log('$_logTag Device location services are DISABLED');

        // Show dialog to user
        await Get.dialog(
          AlertDialog(
            title: const Text('Enable Location Services'),
            content: const Text(
              'Your device\'s GPS/Location services are turned off. '
              'Please enable Location Services in your device settings to use live tracking.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
          barrierDismissible: false,
        );

        return false;
      }

      log('$_logTag Device location services are enabled');
      return true;
    } catch (e) {
      log('$_logTag Error checking location services: $e');
      return false;
    }
  }

  /// Request location permissions before starting tracking
  Future<bool> _requestLocationPermissions() async {
    try {
      // Check current permission status
      PermissionStatus locationStatus = await Permission.location.status;

      if (locationStatus.isDenied) {
        // Request "When in Use" permission first
        locationStatus = await Permission.location.request();

        if (locationStatus.isDenied) {
          log('$_logTag Location permission denied');
          _showTrackingNotification(
            'Location permission is required for live tracking',
            backgroundColor: Colors.red,
            icon: Icons.location_off,
          );
          return false;
        }
      }

      // For Android 10+ and iOS 13+, request "Always" permission
      if (locationStatus.isGranted) {
        PermissionStatus backgroundStatus =
            await Permission.locationAlways.status;

        if (backgroundStatus.isDenied) {
          // Show explanation dialog before requesting Always permission
          await _showAlwaysPermissionDialog();

          backgroundStatus = await Permission.locationAlways.request();

          if (backgroundStatus.isDenied ||
              backgroundStatus.isPermanentlyDenied) {
            log('$_logTag Background location permission denied');
            _showTrackingNotification(
              'Please enable "Allow all the time" location permission for continuous tracking',
              backgroundColor: Colors.orange,
              icon: Icons.warning,
            );
            // Still return true as we have basic location permission
            return true;
          }
        }
      }

      log('$_logTag Location permissions granted successfully');
      return true;
    } catch (e) {
      log('$_logTag Error requesting permissions: $e');
      return false;
    }
  }

  /// Show dialog explaining why "Always" permission is needed
  Future<void> _showAlwaysPermissionDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs to track your location even when the app is closed or not in use. '
          'This ensures continuous tracking during your shift.\n\n'
          'Please select "Allow all the time" on the next screen.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void stopTracking() async {
    if (!isTrackingActive.value) return;

    log('$_logTag Stopping live tracking');

    try {
      _watchdog?.cancel();
      _restartAttempts = 0;
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

  // ENHANCED LOCATION FILTERING - Prevents jumps while allowing identical positions
  void _onLocation(bg.Location location) {
    // 1. ACCURACY FILTERING - Reject very inaccurate readings [web:45]
    if (location.coords.accuracy != null && location.coords.accuracy! > 150) {
      // 150m threshold
      log(
        '$_logTag Location rejected due to poor accuracy: ${location.coords.accuracy}m',
      );
      return;
    }

    // 2. SATELLITE COUNT CHECK (if available)
    // Note: flutter_background_geolocation doesn't expose satellite count directly
    // but accuracy > 100m usually indicates poor satellite reception

    // 3. SMART JUMP DETECTION - This is the key fix for your issue
    if (currentLocation.value != null) {
      double distance = _calculateDistance(
        currentLocation.value!.coords.latitude,
        currentLocation.value!.coords.longitude,
        location.coords.latitude,
        location.coords.longitude,
      );

      // CRITICAL: Detect and filter suspicious jumps [web:45][web:46]
      if (_isSuspiciousJump(distance, location)) {
        log(
          '$_logTag SUSPICIOUS JUMP DETECTED: ${distance}m - REJECTING this location',
        );
        failedAttempts.value++;
        return;
      }

      // Log acceptable movements (including 0m for stationary)
      if (distance == 0) {
        log(
          '$_logTag Identical location accepted (stationary): ${location.coords.latitude}, ${location.coords.longitude}',
        );
      } else if (distance < 50) {
        log('$_logTag Small movement accepted: ${distance}m');
      } else {
        log('$_logTag Normal movement accepted: ${distance}m');
      }
    }

    // 4. TIMESTAMP VALIDATION - Ensure location isn't too old
    try {
      // location.timestamp is an ISO 8601 string like "2025-09-30T07:00:51.176Z"
      final locationTime = DateTime.parse(location.timestamp);
      final now = DateTime.now();
      final ageInSeconds = now.difference(locationTime).inSeconds.abs();

      if (ageInSeconds > 300) {
        // 5 minutes old
        log('$_logTag Location rejected due to age: ${ageInSeconds}s old');
        return;
      }
    } catch (e) {
      log('$_logTag Error parsing timestamp: $e');
      // Don't reject the location if timestamp parsing fails
    }

    // 5. SPEED VALIDATION - Check for unrealistic speeds [web:48]
    if (currentLocation.value != null && location.coords.speed != null) {
      // Convert m/s to km/h for easier understanding
      final speedKmh = (location.coords.speed! * 3.6);
      if (speedKmh > 200) {
        // 200 km/h is unrealistic for most use cases
        log(
          '$_logTag Location rejected due to unrealistic speed: ${speedKmh}km/h',
        );
        return;
      }
    }

    log(
      '$_logTag Location ACCEPTED: ${location.coords.latitude}, ${location.coords.longitude}, accuracy: ${location.coords.accuracy}m',
    );

    // Update local state for UI
    currentLocation.value = location;
    lastUpdateTime.value = DateTime.now().toIso8601String();

    // Reset failed attempts on successful location
    if (failedAttempts.value > 0) {
      failedAttempts.value = 0;
    }
  }

  // ENHANCED JUMP DETECTION LOGIC [web:45][web:48]
  bool _isSuspiciousJump(double distance, bg.Location newLocation) {
    if (currentLocation.value == null) return false;

    final newTimestamp = int.tryParse(newLocation.timestamp.toString()) ?? 0;
    final prevTimestamp =
        int.tryParse(currentLocation.value!.timestamp.toString()) ?? 0;
    final timeDiffSeconds = (newTimestamp - prevTimestamp) / 1000;

    // 1. DISTANCE-BASED FILTERING
    // For stationary/slow-moving scenarios, reject jumps > 200m [web:45]
    if (distance > 200 && timeDiffSeconds < 30) {
      return true; // Likely a GPS error
    }

    // 2. SPEED-BASED FILTERING
    if (timeDiffSeconds > 0) {
      final impliedSpeedMs = distance / timeDiffSeconds; // meters per second
      final impliedSpeedKmh = impliedSpeedMs * 3.6; // km/h

      // Reject if implied speed > 150 km/h (unrealistic for most security guard scenarios)
      if (impliedSpeedKmh > 150) {
        log(
          '$_logTag Implied speed too high: ${impliedSpeedKmh.toStringAsFixed(1)}km/h over ${distance}m in ${timeDiffSeconds}s',
        );
        return true;
      }
    }

    // 3. GEOHASH-BASED FILTERING [web:48]
    // If previous locations were consistently in one area, sudden jump is suspicious
    if (distance > 1000) {
      log('$_logTag Large jump detected: ${distance}m - needs verification');
      return true; // 1km+ jumps are usually errors
    }

    return false; // Location seems legitimate
  }

  // KALMAN FILTER IMPLEMENTATION (Optional - Advanced) [web:48]
  // You can implement this for even better accuracy
  bg.Location? _kalmanFilter(bg.Location newLocation) {
    // Simplified Kalman filter for GPS smoothing
    // This is an advanced technique that combines GPS with accelerometer data
    // Implementation would require additional sensor data and is beyond basic filtering
    return newLocation;
  }

  // ADDITIONAL VALIDATION METHOD
  bool _isLocationRealistic(bg.Location location) {
    // 1. Check if coordinates are within expected bounds (e.g., your country/region)
    // Example for India: lat between 8-37, lon between 68-97
    if (location.coords.latitude < 8 ||
        location.coords.latitude > 37 ||
        location.coords.longitude < 68 ||
        location.coords.longitude > 97) {
      log('$_logTag Location outside expected geographic bounds');
      return false;
    }

    // 2. Check for obviously invalid coordinates
    if (location.coords.latitude == 0.0 && location.coords.longitude == 0.0) {
      log('$_logTag Invalid null island coordinates');
      return false;
    }

    return true;
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
