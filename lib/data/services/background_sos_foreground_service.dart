import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BackgroundSosForegroundService {
  static const String _logTag = '[BackgroundSosService]';
  static const String notificationChannelId = 'sos_checkin_channel';
  static const int notificationId = 999;

  // Configuration keys
  static const String _keyUserId = 'sos_user_id';
  static const String _keyCompanyId = 'sos_company_id';
  static const String _keySiteId = 'sos_site_id';
  static const String _keyIntervalMinutes = 'sos_interval_minutes';
  static const String _keyResponseMinutes = 'sos_response_minutes';
  static const String _keyApiBaseUrl = 'sos_api_base_url';
  static const String _keyServiceEnabled = 'sos_service_enabled';
  static const String _keyLastCheckIn = 'sos_last_checkin';
  static const String _keyPendingCheckInId = 'pending_checkin_id';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'SOS Safety Check-ins',
      description: 'Periodic safety check-in notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'SOS Safety Service',
        initialNotificationContent: 'Safety check-ins are active',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    log('$_logTag Background SOS service started');

    Timer? checkInTimer;
    Timer? responseTimer;
    String? pendingCheckInId;

    // Listen for stop command
    service.on('stopService').listen((event) {
      log('$_logTag Received stop command');
      checkInTimer?.cancel();
      responseTimer?.cancel();
      service.stopSelf();
    });

    // Listen for configuration updates
    service.on('updateConfig').listen((event) async {
      log('$_logTag Received config update: $event');
      checkInTimer?.cancel();
      responseTimer?.cancel();
      await _saveConfigToPrefs(event);
      checkInTimer = await _startCheckInTimer(service);
    });

    // Listen for check-in responses from main app
    service.on('checkInResponse').listen((event) async {
      log('$_logTag Received check-in response: ${event?['status']}');
      responseTimer?.cancel();
      pendingCheckInId = null;
      await _handleCheckInResponse(event?['status'], event?['checkInId']);

      // Update notification
      // service.setForegroundNotificationInfo(
      //   title: 'SOS Safety Service',
      //   content:
      //       'Last check-in: ${DateTime.now().toString().substring(11, 16)}',
      // );
    });

    // Start initial check-in timer
    checkInTimer = await _startCheckInTimer(service);
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  static Future<Timer?> _startCheckInTimer(ServiceInstance service) async {
    try {
      final config = await _loadConfigFromPrefs();
      if (config == null || !config['serviceEnabled']) {
        log('$_logTag SOS service disabled or no config found');
        return null;
      }

      final int intervalMinutes = config['intervalMinutes'] ?? 1;
      final int responseMinutes = config['responseMinutes'] ?? 1;

      log(
        '$_logTag Starting SOS check-in timer: ${intervalMinutes}min interval',
      );

      // Schedule periodic check-ins
      return Timer.periodic(
        Duration(minutes: intervalMinutes),
        (timer) => _performCheckIn(service, responseMinutes),
      );
    } catch (e) {
      log('$_logTag Error starting check-in timer: $e');
      return null;
    }
  }

  static Future<void> _performCheckIn(
    ServiceInstance service,
    int responseMinutes,
  ) async {
    try {
      final checkInId = DateTime.now().millisecondsSinceEpoch.toString();
      final promptTime = DateTime.now().toIso8601String();

      log('$_logTag Performing SOS check-in: $checkInId');

      // Store pending check-in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPendingCheckInId, checkInId);

      // Show notification with actions
      await _showCheckInNotification(checkInId, responseMinutes, promptTime);

      // Update foreground notification
      // service.setNotificationInfo(
      //   title: 'Safety Check-in Required',
      //   content: 'Please respond within $responseMinutes minutes',
      // );

      // Start response timeout
      Timer(Duration(minutes: responseMinutes), () async {
        final currentPendingId = (await SharedPreferences.getInstance())
            .getString(_keyPendingCheckInId);

        if (currentPendingId == checkInId) {
          log('$_logTag Check-in timeout: $checkInId');
          await _handleMissedCheckIn(checkInId, promptTime);

          // service.setNotificationInfo(
          //   title: 'SOS Safety Service',
          //   content: 'Missed check-in reported to admin',
          // );
        }
      });
    } catch (e) {
      log('$_logTag Error performing check-in: $e');
    }
  }

  static Future<void> _showCheckInNotification(
    String checkInId,
    int responseMinutes,
    String promptTime,
  ) async {
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();
 AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  notificationChannelId,
  'SOS Safety Check-ins',
  channelDescription: 'Periodic safety check-in notifications',
  importance: Importance.max, // Changed to max
  priority: Priority.high,
  fullScreenIntent: true,
  category: AndroidNotificationCategory.alarm,
  visibility: NotificationVisibility.public,
  ongoing: false, // Changed to false so it can be tapped
  autoCancel: true, // Changed to true
  playSound: true,
  enableVibration: true,
  sound: const RawResourceAndroidNotificationSound('notification'), // Use default sound
  vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
  actions: [
    AndroidNotificationAction(
      'all_ok',
      'All OK ✅',
      titleColor: Color.fromARGB(255, 0, 128, 0),
    ),
    AndroidNotificationAction(
      'sos',
      'SOS 🆘', 
      titleColor: Color.fromARGB(255, 255, 0, 0),
    ),
    AndroidNotificationAction(
      'dismiss',
      'Dismiss',
      titleColor: Color.fromARGB(255, 128, 128, 128),
    ),
  ],
);

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      int.parse(checkInId.substring(checkInId.length - 6)),
      '🚨 Safety Check-in Required',
      'Please confirm your status within $responseMinutes minutes',
      notificationDetails,
      payload: jsonEncode({
        'type': 'sos_checkin',
        'checkInId': checkInId,
        'promptTime': promptTime,
      }),
    );
  }

  static Future<void> _handleCheckInResponse(
    String status,
    String checkInId,
  ) async {
    try {
      final config = await _loadConfigFromPrefs();
      if (config == null) return;

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        log('$_logTag Error getting location: $e');
      }

      final checkInData = {
        'userId': config['userId'],
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'promptTime': DateTime.now().toIso8601String(),
        'response': status,
        'companyID': config['companyId'],
        'siteId': config['siteId'],
      };

      await _sendCheckInToApi(checkInData, config['apiBaseUrl']);

      // Clear pending check-in
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingCheckInId);
      await prefs.setInt(
        _keyLastCheckIn,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      log('$_logTag Error handling check-in response: $e');
    }
  }

  static Future<void> _handleMissedCheckIn(
    String checkInId,
    String promptTime,
  ) async {
    try {
      final config = await _loadConfigFromPrefs();
      if (config == null) return;

      final checkInData = {
        'userId': config['userId'],
        'latitude': 0.0,
        'longitude': 0.0,
        'promptTime': promptTime,
        'response': 'Missed',
        'companyID': config['companyId'],
        'siteId': config['siteId'],
      };

      await _sendCheckInToApi(checkInData, config['apiBaseUrl']);

      // Clear pending check-in
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingCheckInId);
    } catch (e) {
      log('$_logTag Error handling missed check-in: $e');
    }
  }

  static Future<void> _sendCheckInToApi(
    Map<String, dynamic> checkInData,
    String apiBaseUrl,
  ) async {
    try {
      log('$_logTag Sending check-in to API: ${checkInData['response']}');

      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/Tracking/safety-checkin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(checkInData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          log('$_logTag Check-in sent successfully');
        } else {
          throw Exception('Server returned false status');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      log('$_logTag Error sending check-in: $e');

      // Store for retry
      final prefs = await SharedPreferences.getInstance();
      final pendingCheckIns = prefs.getStringList('pending_checkins') ?? [];
      pendingCheckIns.add(jsonEncode(checkInData));
      await prefs.setStringList('pending_checkins', pendingCheckIns);
    }
  }

  static Future<void> _saveConfigToPrefs(Map<String, dynamic>? config) async {
    if (config == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, config['userId'] ?? '');
    await prefs.setString(_keyCompanyId, config['companyId'] ?? '');
    await prefs.setString(_keySiteId, config['siteId'] ?? '');
    await prefs.setInt(_keyIntervalMinutes, config['intervalMinutes'] ?? 1);
    await prefs.setInt(_keyResponseMinutes, config['responseMinutes'] ?? 1);
    await prefs.setString(_keyApiBaseUrl, config['apiBaseUrl'] ?? '');
    await prefs.setBool(_keyServiceEnabled, config['serviceEnabled'] ?? false);
  }

  static Future<Map<String, dynamic>?> _loadConfigFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_keyUserId)) return null;

    return {
      'userId': prefs.getString(_keyUserId) ?? '',
      'companyId': prefs.getString(_keyCompanyId) ?? '',
      'siteId': prefs.getString(_keySiteId) ?? '',
      'intervalMinutes': prefs.getInt(_keyIntervalMinutes) ?? 1,
      'responseMinutes': prefs.getInt(_keyResponseMinutes) ?? 1,
      'apiBaseUrl': prefs.getString(_keyApiBaseUrl) ?? '',
      'serviceEnabled': prefs.getBool(_keyServiceEnabled) ?? false,
    };
  }

  // Public methods
  static Future<void> startBackgroundSosService({
    required String userId,
    required String companyId,
    required String siteId,
    required int intervalMinutes,
    required int responseWindowMinutes,
    required String apiBaseUrl,
  }) async {
    await initializeService();

    final service = FlutterBackgroundService();

    final config = {
      'userId': userId,
      'companyId': companyId,
      'siteId': siteId,
      'intervalMinutes': intervalMinutes,
      'responseMinutes': responseWindowMinutes,
      'apiBaseUrl': apiBaseUrl,
      'serviceEnabled': true,
    };

    await _saveConfigToPrefs(config);

    if (await service.isRunning()) {
      service.invoke('updateConfig', config);
    } else {
      await service.startService();
      await Future.delayed(const Duration(milliseconds: 500));
      service.invoke('updateConfig', config);
    }

    log('$_logTag Background SOS service started');
  }

  static Future<void> stopBackgroundSosService() async {
    final service = FlutterBackgroundService();

    await _saveConfigToPrefs({'serviceEnabled': false});

    if (await service.isRunning()) {
      service.invoke('stopService');
    }

    // Cancel all notifications
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await notificationsPlugin.cancelAll();

    log('$_logTag Background SOS service stopped');
  }

  static Future<bool> isBackgroundSosServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
