import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:security_guard/core/api/api_constants.dart';

class BackgroundSosService {
  static const String _checkInTaskName = "sosCheckInTask";
  static const String _sosNotificationChannelId = "sos_checkin_channel";
  static const String _sosNotificationChannelName =
      "SOS Check-in Notifications";

  static FlutterLocalNotificationsPlugin? _localNotificationsPlugin;
  static bool _isInitialized = false;

  // Initialize the background service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeNotifications();
    await _initializeWorkManager();

    _isInitialized = true;
    print('🚀 Background SOS Service initialized');
  }

  // Initialize local notifications
  static Future<void> _initializeNotifications() async {
    _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      _sosNotificationChannelId,
      _sosNotificationChannelName,
      description: 'Notifications for SOS safety check-ins',
      importance: Importance.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('sos_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Initialize WorkManager
  static Future<void> _initializeWorkManager() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  // Start background SOS monitoring
  static Future<void> startBackgroundService({
    required int intervalMinutes,
    required int responseWindowMinutes,
    required String userId,
  }) async {
    if (!_isInitialized) await initialize();

    // Store configuration in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sos_interval_minutes', intervalMinutes);
    await prefs.setInt('sos_response_minutes', responseWindowMinutes);
    await prefs.setString('sos_user_id', userId);
    await prefs.setBool('sos_service_active', true);
    await prefs.setInt(
      'sos_last_checkin',
      DateTime.now().millisecondsSinceEpoch,
    );

    // Cancel existing tasks
    await Workmanager().cancelAll();

    // Register periodic task
    await Workmanager().registerPeriodicTask(
      _checkInTaskName,
      _checkInTaskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(networkType: NetworkType.connected),
      inputData: {
        'intervalMinutes': intervalMinutes,
        'responseMinutes': responseWindowMinutes,
        'userId': userId,
      },
    );

    print(
      '✅ Background SOS service started with ${intervalMinutes}min interval',
    );
  }

  // Stop background SOS monitoring
  static Future<void> stopBackgroundService() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sos_service_active', false);

    await Workmanager().cancelAll();
    await _cancelAllNotifications();

    print('🛑 Background SOS service stopped');
  }

  // Handle notification tap
@pragma('vm:entry-point')
static void _onNotificationTapped(NotificationResponse response) {
  log(' SOS Notification tapped: ${response.payload}');
  
  if (response.payload != null) {
    final data = json.decode(response.payload!);
    final type = data['type'] as String;
    
    if (type == 'sos_checkin') {
      // Send message to main app to show dialog
      _sendMessageToMainApp({
        'action': 'show_sos_dialog',
        'checkInId': data['checkInId'],
        'promptTime': data['promptTime'],
      });
    }
  }
  
  // Handle notification actions (All OK, SOS, Dismiss buttons)
  if (response.actionId != null) {
    _handleNotificationAction(response.actionId!, response.payload ?? '');
  }
}


static void _sendMessageToMainApp(Map<String, dynamic> message) {
  try {
    final service = FlutterBackgroundService();
    service.invoke('notificationTapped', message);
  } catch (e) {
    log(' Error sending message to main app: $e');
  }
}

  // Send message to main isolate
  static void _sendPortMessage(Map<String, dynamic> message) {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(
      'sos_main_port',
    );
    sendPort?.send(message);
  }

  // Show SOS notification
  static Future<void> showSosNotification({
    required String checkInId,
    required int responseMinutes,
    required String promptTime,
  }) async {
    if (_localNotificationsPlugin == null) return;

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _sosNotificationChannelId,
          _sosNotificationChannelName,
          channelDescription: 'SOS Safety Check-in Required',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'SOS Check-in Required',
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('sos_alert'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'all_ok',
              'All OK ✅',
              titleColor: Color.fromARGB(255, 0, 128, 0),
            ),
            const AndroidNotificationAction(
              'sos',
              'SOS 🆘',
              titleColor: Color.fromARGB(255, 255, 0, 0),
            ),
            const AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              titleColor: Color.fromARGB(255, 128, 128, 128),
            ),
          ],
        );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin!.show(
      int.parse(checkInId),
      '🚨 Safety Check-in Required',
      'Please confirm your status within $responseMinutes minutes',
      notificationDetails,
      payload: json.encode({
        'type': 'sos_checkin',
        'checkInId': checkInId,
        'responseMinutes': responseMinutes,
        'promptTime': promptTime,
      }),
    );
  }

  // Cancel all notifications
  static Future<void> _cancelAllNotifications() async {
    await _localNotificationsPlugin?.cancelAll();
  }

  // Handle notification action response
  static Future<void> _handleNotificationAction(
    String action,
    String payload,
  ) async {
    print('📱 Notification action: $action');

    try {
      final data = json.decode(payload);
      final checkInId = data['checkInId'] as String;
      final promptTime = data['promptTime'] as String;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('sos_user_id') ?? '';
      final companyId = prefs.getString('user_company_id') ?? '';
      final siteId = prefs.getString('user_site_id') ?? '';

      String responseType;
      Color feedbackColor;
      String feedbackMessage;

      switch (action) {
        case 'all_ok':
          responseType = 'AllOK';
          feedbackColor = Colors.green;
          feedbackMessage = '✅ Check-in successful';
          break;
        case 'sos':
          responseType = 'SOS';
          feedbackColor = Colors.red;
          feedbackMessage = '🆘 SOS Alert sent';
          break;
        case 'dismiss':
          responseType = 'Ignore';
          feedbackColor = Colors.orange;
          feedbackMessage = 'Check-in dismissed';
          break;
        default:
          return;
      }

      await _sendCheckInResponse(
        responseType,
        userId,
        checkInId,
        promptTime,
        companyId,
        siteId,
      );
      await _cancelAllNotifications();
      _showResponseFeedback(feedbackMessage, feedbackColor);

      // Update last check-in time
      await prefs.setInt(
        'sos_last_checkin',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('❌ Error handling notification action: $e');
      _showResponseFeedback('Error sending response', Colors.red);
    }
  }

  // Send check-in response to server
  static Future<void> _sendCheckInResponse(
    String status,
    String userId,
    String checkInId,
    String promptTime,
    String companyId,
    String siteId,
  ) async {
    try {
      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('⚠️ Error getting location: $e');
        // Continue without location
      }

      final checkInData = {
        'userId': userId,
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'promptTime': promptTime,
        'response': status,
        'companyID': companyId,
        'siteId': siteId,
      };

      print('📤 Sending check-in response: $status for user: $userId');

      final response = await http
          .post(
            Uri.parse('$BASE_URL/Tracking/safety-checkin'),
            headers: {'Content-Type': 'application/json', 'accept': '*/*'},
            body: json.encode(checkInData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          print('✅ Check-in sent successfully. ID: ${responseData['id']}');
        } else {
          throw Exception('Server returned false status');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending check-in response: $e');

      // Store for retry when online
      final prefs = await SharedPreferences.getInstance();
      final pendingCheckIns = prefs.getStringList('pending_checkins') ?? [];
      final checkInData = {
        'userId': userId,
        'latitude': 0.0,
        'longitude': 0.0,
        'promptTime': promptTime,
        'response': status,
        'companyID': companyId,
        'siteId': siteId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      pendingCheckIns.add(json.encode(checkInData));
      await prefs.setStringList('pending_checkins', pendingCheckIns);

      rethrow;
    }
  }

  // Send SOS alert to server (legacy method, now uses _sendCheckInResponse)
  static Future<void> _sendSosAlert(String userId, String checkInId) async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('user_company_id') ?? '';
    final siteId = prefs.getString('user_site_id') ?? '';
    final promptTime = DateTime.now().toIso8601String();

    await _sendCheckInResponse(
      'SOS',
      userId,
      checkInId,
      promptTime,
      companyId,
      siteId,
    );
  }

  // Show response feedback
  static void _showResponseFeedback(String message, Color color) {
    _sendPortMessage({
      'action': 'show_snackbar',
      'message': message,
      'color': color.value,
    });
  }

  // Show timeout notification
  static Future<void> showTimeoutNotification(String checkInId) async {
    if (_localNotificationsPlugin == null) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _sosNotificationChannelId,
          _sosNotificationChannelName,
          channelDescription: 'Missed SOS Check-in Alert',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin!.show(
      999999, // Fixed ID for timeout notifications
      '⚠️ Missed Safety Check-in',
      'No response received. Alert sent to admin.',
      notificationDetails,
    );
  }
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 Background task executed: $task');

    switch (task) {
      case BackgroundSosService._checkInTaskName:
        return await _handleSosCheckIn(inputData!);
      default:
        return Future.value(true);
    }
  });
}

// Handle SOS check-in in background
Future<bool> _handleSosCheckIn(Map<String, dynamic> inputData) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isServiceActive = prefs.getBool('sos_service_active') ?? false;

    if (!isServiceActive) {
      print('📴 SOS service is inactive, skipping check-in');
      return true;
    }

    final intervalMinutes = inputData['intervalMinutes'] as int;
    final responseMinutes = inputData['responseMinutes'] as int;
    final userId = inputData['userId'] as String;

    final lastCheckIn = prefs.getInt('sos_last_checkin') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastCheckIn = Duration(milliseconds: now - lastCheckIn);

    // Check if it's time for a check-in
    if (timeSinceLastCheckIn.inMinutes >= intervalMinutes) {
      final checkInId = DateTime.now().millisecondsSinceEpoch.toString();
      final promptTime = DateTime.now().toIso8601String();

      // Show notification
      await BackgroundSosService.showSosNotification(
        checkInId: checkInId,
        responseMinutes: responseMinutes,
        promptTime: promptTime,
      );

      // Store pending check-in info
      await prefs.setString('pending_checkin_id', checkInId);
      await prefs.setString('pending_checkin_prompt_time', promptTime);

      // Schedule timeout check
      _scheduleTimeoutCheck(checkInId, responseMinutes, promptTime);

      print('✅ Background SOS check-in notification sent');
    }

    return true;
  } catch (e) {
    print('❌ Error in background SOS check-in: $e');
    return false;
  }
}

// Schedule timeout check
void _scheduleTimeoutCheck(
  String checkInId,
  int responseMinutes,
  String promptTime,
) {
  Timer(Duration(minutes: responseMinutes), () async {
    final prefs = await SharedPreferences.getInstance();
    final pendingCheckInId = prefs.getString('pending_checkin_id');

    if (pendingCheckInId == checkInId) {
      // No response received, send missed check-in alert
      print('⏰ SOS check-in timeout for ID: $checkInId');

      final userId = prefs.getString('sos_user_id') ?? '';
      final companyId = prefs.getString('user_company_id') ?? '';
      final siteId = prefs.getString('user_site_id') ?? '';

      try {
        await BackgroundSosService._sendCheckInResponse(
          'Missed',
          userId,
          checkInId,
          promptTime,
          companyId,
          siteId,
        );
      } catch (e) {
        print('❌ Error sending missed check-in: $e');
      }

      // Clear pending check-in
      await prefs.remove('pending_checkin_id');
      await prefs.remove('pending_checkin_prompt_time');

      // Show timeout notification
      await BackgroundSosService.showTimeoutNotification(checkInId);
    }
  });
}
