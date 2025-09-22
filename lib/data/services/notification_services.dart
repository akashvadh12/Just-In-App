// lib/notification_services.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:security_guard/data/services/sos_checkin_service.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/navigation_controller.dart';
import 'package:security_guard/shared/widgets/sos_checkIn_dialog.dart';

class NotificationServices {
  NotificationServices();

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final BottomNavController controller = Get.put(BottomNavController());

  // Channel + fixed notification ids + tag
  static const String safetyChannelId = 'safety_checkin_channel';
  static const String safetyChannelName = 'Safety Check-In';
  static const String safetyChannelDescription = 'Safety check-in alerts';

  // Fixed IDs so .show(...) with same id updates/replaces notification.
  static const int safetyNotificationId = 12345;
  static const int generalNotificationId = 67890;

  // Android tag — Android will replace notifications with same tag + id.
  static const String safetyAndroidTag = 'safety_checkin_tag';
  // iOS thread identifier — for grouping / replacement behavior on iOS local notifications.
  static const String iosThreadIdentifier = 'safety_checkin_thread';

  // Check if GetX app is fully ready
  static bool get isAppFullyReady {
    try {
      final binding = WidgetsBinding.instance;
      final lifecycleState = binding.lifecycleState;
      final hasContext = Get.context != null;
      final isMaterialAppReady = Get.key.currentContext != null;
      
      return lifecycleState != null && 
             lifecycleState != AppLifecycleState.detached &&
             hasContext &&
             isMaterialAppReady;
    } catch (e) {
      print('Error checking app ready state: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    try {
      await _initLocalNotification();
      await _requestPermissions();

      _messaging.onTokenRefresh.listen((token) {
        print('FCM token refreshed: $token');
      });

      _setupFirebaseHandlers();
      
      // Delay initial message check to ensure app is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkInitialMessage();
      });
      
    } catch (e, st) {
      print('NotificationServices.initialize error: $e\n$st');
    }
  }

  Future<void> _initLocalNotification() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings("ic_stat_safety");

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationResponse(response);
      },
    );

    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

    final AndroidNotificationChannel safetyChannel = AndroidNotificationChannel(
      safetyChannelId,
      safetyChannelName,
      description: safetyChannelDescription,
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('safety_alert'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(safetyChannel);
      print('Android safety channel created');
    } catch (e) {
      print('Error creating Android notification channel: $e');
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    print('Local notifications initialized');
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  void _setupFirebaseHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      print('onMessage: ${msg}');

      // Show local notification (prevents duplicate system auto-notifications when you use data messages).
    _showLocalNotificationFromRemote(msg, autoDismiss: true);

      if (_isSafetyCheckin(msg.data)) {
        // Show dialog for foreground safety check-in
        _handleSafetyCheckInNotification(msg.data);
        return;
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      print('onMessageOpenedApp: ${msg}');
      if (_isSafetyCheckin(msg.data)) {
        _handleSafetyCheckInNotification(msg.data);
        return;
      }
      
      // Wait for app to be ready before navigation
      _waitForAppReadyThenNavigate();
    });
  }

  void _waitForAppReadyThenNavigate() {
    if (isAppFullyReady) {
      controller.currentIndex.value = 3;
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        _waitForAppReadyThenNavigate();
      });
    }
  }

  // Updated method with better timing control
  Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('getInitialMessage: ${initialMessage.data}');
        if (_isSafetyCheckin(initialMessage.data)) {
          // For killed state, wait longer for app to be fully ready
          _waitForAppReadyAndShowSafetyDialog(initialMessage.data, isFromKilledState: true);
        } else {
          _waitForAppReadyThenNavigate();
        }
      }
    } catch (e) {
      print('Error checking initial message: $e');
    }
  }

  // Enhanced method for killed state handling
  void _waitForAppReadyAndShowSafetyDialog(Map<String, dynamic> data, {bool isFromKilledState = false}) {
    final int maxRetries = isFromKilledState ? 20 : 10;  // More retries for killed state
    final int delayMs = isFromKilledState ? 300 : 200;   // Longer delay for killed state
    int retryCount = 0;
    
    void checkAndShow() {
      if (isAppFullyReady && retryCount < maxRetries) {
        _showSafetyDialogSafely(data);
        return;
      }
      
      retryCount++;
      if (retryCount < maxRetries) {
        Future.delayed(Duration(milliseconds: delayMs), checkAndShow);
      } else {
        print('Max retries reached, app might not be ready');
        // Last attempt
        if (Get.context != null) {
          _showSafetyDialogSafely(data);
        }
      }
    }
    
    // Initial delay for killed state
    if (isFromKilledState) {
      Future.delayed(const Duration(milliseconds: 2000), checkAndShow);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => checkAndShow());
    }
  }

void _showSafetyDialogSafely(Map<String, dynamic> data) {
  if (Get.isDialogOpen ?? false) {
    return;
  }
  
  final checkInId = data['checkInId']?.toString() ?? 
                   data['check_in_id']?.toString() ?? '0';
  
  print('Showing safety check-in dialog from notification: $checkInId');
  
  NotificationServices.cancelSafetyNotification();
  
  try {
    // Use the SOS service method for notification-triggered dialogs
    final sosService = Get.find<SosCheckInService>();
    sosService.showCheckInDialogFromNotification(checkInId);
  } catch (e) {
    print('Error showing safety dialog: $e');
  }
}


  static bool _isSafetyCheckin(Map<String, dynamic> data) {
    try {
      return (data['Type'] == 'safety_checkin' ||
          data['type'] == 'safety_checkin' ||
          data['event'] == 'safety_checkin');
    } catch (_) {
      return false;
    }
  }

  void _handleSafetyCheckInNotification(Map<String, dynamic> data) {
    final checkInId = data['checkInId']?.toString() ?? 
                     data['check_in_id']?.toString() ?? '0';
    print('Handling safety check-in: $checkInId');

    if (Get.isDialogOpen ?? false) {
      return;
    }

    NotificationServices.cancelSafetyNotification();

    if (isAppFullyReady) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _showSafetyDialogSafely(data);
      });
    } else {
      _waitForAppReadyAndShowSafetyDialog(data);
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final Map<String, dynamic> data = _stringToMap(payload);

        print('Notification tapped with payload: $data');
        if (_isSafetyCheckin(data)) {
          _handleSafetyCheckInNotification(data);
          return;
        }
      } catch (e) {
        print('Error parsing payload: $e');
      }
    }

    _waitForAppReadyThenNavigate();
  }

  static Map<String, dynamic> _stringToMap(String payload) {
    try {
      return Map<String, dynamic>.from(jsonDecode(payload));
    } catch (_) {
      return {};
    }
  }








  // ... rest of your existing methods remain the same ...
  // 2) Add an autoDismiss flag and use Android timeoutAfter + a short delayed cancel for all platforms
Future<void> _showLocalNotificationFromRemote(RemoteMessage message, {bool autoDismiss = false}) async {
  try {
    final isSafety = _isSafetyCheckin(message.data);
    final notificationId = isSafety ? safetyNotificationId : generalNotificationId;

    final androidDetails = AndroidNotificationDetails(
      safetyChannelId,
      safetyChannelName,
      channelDescription: safetyChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('safety_alert'),
      icon: "ic_stat_safety",
      tag: isSafety ? safetyAndroidTag : null,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      enableVibration: true,
      timeoutAfter: autoDismiss ? 1500 : null, // auto-cancel after ~1.5s on Android
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'safety_alert.mp3',
      threadIdentifier: iosThreadIdentifier,
    );

    final platformDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    final title = message.notification?.title ?? message.data['title'] ?? 'Alert';
    final body  = message.notification?.body  ?? message.data['body']  ?? 'Please responce to sefety checkin';

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: jsonEncode(message.data.isNotEmpty ? message.data : {'message': 'no-data'}),
    );

    // iOS (and a fallback for Android): explicitly cancel shortly after showing
    if (autoDismiss) {
      Future.delayed(const Duration(seconds: 2), () {
        _flutterLocalNotificationsPlugin.cancel(notificationId);
      });
    }
  } catch (e) {
    print('Error showing local notification from remote: $e');
  }
}


  // ... keep all your other existing methods (showBackgroundNotification, getDeviceToken, etc.) ...

  static Future<void> cancelSafetyNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(safetyNotificationId);
    print('Safety notification cancelled');
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('All notifications cancelled');
  }

  Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM token: $token');
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String t) => _messaging.subscribeToTopic(t);
  Future<void> unsubscribeFromTopic(String t) => _messaging.unsubscribeFromTopic(t);

  // Keep your existing showBackgroundNotification method as-is
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    // ... your existing implementation
  }
}
