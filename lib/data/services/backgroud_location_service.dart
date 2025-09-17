import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BackgroundLocationService {
  static const String _logTag = '[BackgroundLocationService]';
  static const String notificationChannelId = 'live_tracking_channel';
  static const int notificationId = 888;

  // Configuration keys for SharedPreferences
  static const String _keyUserId = 'bg_user_id';
  static const String _keyCompanyId = 'bg_company_id';
  static const String _keySiteId = 'bg_site_id';
  static const String _keyIsClocked = 'bg_is_clocked';
  static const String _keyTrackingInterval = 'bg_tracking_interval';
  static const String _keyApiBaseUrl = 'bg_api_base_url';
  static const String _keyAuthToken = 'bg_auth_token';
  static const String _keyIsTrackingEnabled = 'bg_tracking_enabled';

// Show notification only when app is in background
static Future<void> initializeService({bool showNotification = true}) async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: showNotification, // Make it configurable
      notificationChannelId: showNotification ? notificationChannelId : null,
      initialNotificationTitle: 'Live Tracking',
      initialNotificationContent: 'Tracking your location...',
      foregroundServiceNotificationId: notificationId ,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}


  // Main entry point for background service
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    log('$_logTag Background service started');
    
    Timer? locationTimer;
    
    // Listen for stop command from main app
    service.on('stopService').listen((event) {
      log('$_logTag Received stop command');
      locationTimer?.cancel();
      service.stopSelf();
    });

    // Listen for configuration updates from main app
    service.on('updateConfig').listen((event) async {
      log('$_logTag Received config update: $event');
      locationTimer?.cancel();
      await _saveConfigToPrefs(event);
      locationTimer = await _startLocationTracking(service);
    });

    // Start initial location tracking
    locationTimer = await _startLocationTracking(service);
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    log('$_logTag iOS background execution');
    return true;
  }

  static Future<Timer?> _startLocationTracking(ServiceInstance service) async {
    try {
      final config = await _loadConfigFromPrefs();
      
      if (config == null || !config['trackingEnabled']) {
        log('$_logTag Tracking disabled or no config found');
        return null;
      }

      final int intervalSeconds = config['trackingInterval'] ?? 300;
      
      log('$_logTag Starting location tracking with ${intervalSeconds}s interval');
      
      // Get location immediately
      await _getCurrentLocationAndSend(service, config);
      
      // Start periodic tracking
      return Timer.periodic(
        Duration(seconds: intervalSeconds),
        (_) => _getCurrentLocationAndSend(service, config),
      );
      
    } catch (e) {
      log('$_logTag Error starting location tracking: $e');
      return null;
    }
  }

  static Future<void> _getCurrentLocationAndSend(
    ServiceInstance service,
    Map<String, dynamic> config,
  ) async {
    try {
      log('$_logTag Getting current location...');
      
      // Check if location services are enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        log('$_logTag Location services are disabled');
        _updateNotification(service, 'GPS disabled');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      log('$_logTag Location obtained: ${position.latitude}, ${position.longitude}');
      
      // Send to server
      final success = await _sendLocationToServer(position, config);
      
      _updateNotification(
        service,
        success ? 'Location updated' : 'Send failed, will retry',
      );
      
      // Notify main app if it's running
      service.invoke('locationUpdate', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'success': success,
      });
      
    } catch (e) {
      log('$_logTag Error getting/sending location: $e');
      _updateNotification(service, 'Location error: ${e.toString().substring(0, 20)}...');
    }
  }

  static Future<bool> _sendLocationToServer(
    Position position,
    Map<String, dynamic> config,
  ) async {
    try {
      final locationData = {
        'userId': config['userId'],
        'latitude': position.latitude,
        'longitude': position.longitude,
        'isClockedIn': config['isClocked'] == true,
        'isClockedOut': config['isClocked'] == false,
        'companyID': config['companyId'],
        'siteId': config['siteId'],
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': position.accuracy,
      };

      final String baseUrl = config['apiBaseUrl'] ?? '';
      final String? authToken = config['authToken'];
      
      if (baseUrl.isEmpty) {
        log('$_logTag API base URL not configured');
        return false;
      }

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      log('$_logTag Sending location to: $baseUrl/Tracking/live-tracking');
      
      final response = await http.post(
        Uri.parse('$baseUrl/Tracking/live-tracking'),
        headers: headers,
        body: jsonEncode(locationData),
      ).timeout(const Duration(seconds: 30));

      log('$_logTag Server response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          log('$_logTag Location sent successfully');
          return true;
        } else {
          log('$_logTag Server returned false status: ${responseData['message']}');
          return false;
        }
      } else {
        log('$_logTag HTTP error: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      log('$_logTag Error sending location: $e');
      return false;
    }
  }

  static void _updateNotification(ServiceInstance service, String content) {
    // service.setNotificationInfo(
    //   title: 'Live Tracking Active',
    //   content: content,
    // );
  }

  static Future<void> _saveConfigToPrefs(Map<String, dynamic>? config) async {
    if (config == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_keyUserId, config['userId'] ?? '');
    await prefs.setString(_keyCompanyId, config['companyId'] ?? '');
    await prefs.setString(_keySiteId, config['siteId'] ?? '');
    await prefs.setBool(_keyIsClocked, config['isClocked'] ?? false);
    await prefs.setInt(_keyTrackingInterval, config['trackingInterval'] ?? 300);
    await prefs.setString(_keyApiBaseUrl, config['apiBaseUrl'] ?? '');
    await prefs.setString(_keyAuthToken, config['authToken'] ?? '');
    await prefs.setBool(_keyIsTrackingEnabled, config['trackingEnabled'] ?? false);
    
    log('$_logTag Configuration saved to preferences');
  }

  static Future<Map<String, dynamic>?> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey(_keyUserId)) {
      log('$_logTag No configuration found in preferences');
      return null;
    }
    
    final config = {
      'userId': prefs.getString(_keyUserId) ?? '',
      'companyId': prefs.getString(_keyCompanyId) ?? '',
      'siteId': prefs.getString(_keySiteId) ?? '',
      'isClocked': prefs.getBool(_keyIsClocked) ?? false,
      'trackingInterval': prefs.getInt(_keyTrackingInterval) ?? 300,
      'apiBaseUrl': prefs.getString(_keyApiBaseUrl) ?? '',
      'authToken': prefs.getString(_keyAuthToken) ?? '',
      'trackingEnabled': prefs.getBool(_keyIsTrackingEnabled) ?? false,
    };
    
    log('$_logTag Configuration loaded from preferences');
    return config;
  }

  // Public methods for main app to control background service
  static Future<void> startBackgroundTracking({
    required String userId,
    required String companyId,
    required String siteId,
    required bool isClocked,
    required int trackingInterval,
    required String apiBaseUrl,
    String? authToken,
  }) async {
    final service = FlutterBackgroundService();
    
    final config = {
      'userId': userId,
      'companyId': companyId,
      'siteId': siteId,
      'isClocked': isClocked,
      'trackingInterval': trackingInterval,
      'apiBaseUrl': apiBaseUrl,
      'authToken': authToken,
      'trackingEnabled': true,
    };
    
    await _saveConfigToPrefs(config);
    
    if (await service.isRunning()) {
      service.invoke('updateConfig', config);
    } else {
      await service.startService();
      // Small delay to ensure service is started before sending config
      await Future.delayed(const Duration(milliseconds: 500));
      service.invoke('updateConfig', config);
    }
    
    log('$_logTag Background tracking started');
  }

  static Future<void> stopBackgroundTracking() async {
    final service = FlutterBackgroundService();
    
    // Mark as disabled in preferences
    await _saveConfigToPrefs({'trackingEnabled': false});
    
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
    
    log('$_logTag Background tracking stopped');
  }

  static Future<void> updateBackgroundConfig({
    required bool isClocked,
    required int trackingInterval,
  }) async {
    final service = FlutterBackgroundService();
    
    if (await service.isRunning()) {
      final currentConfig = await _loadConfigFromPrefs();
      if (currentConfig != null) {
        currentConfig['isClocked'] = isClocked;
        currentConfig['trackingInterval'] = trackingInterval;
        
        await _saveConfigToPrefs(currentConfig);
        service.invoke('updateConfig', currentConfig);
        
        log('$_logTag Background config updated');
      }
    }
  }

  static Future<bool> isBackgroundTrackingRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}