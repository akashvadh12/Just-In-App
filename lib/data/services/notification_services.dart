// lib/notification_services.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  Future<void> initialize() async {
    try {
      await _initLocalNotification();
      await _requestPermissions();

      _messaging.onTokenRefresh.listen((token) {
        print('FCM token refreshed: $token');
      });

      _setupFirebaseHandlers();
      _checkInitialMessage();
    } catch (e, st) {
      print('NotificationServices.initialize error: $e\n$st');
    }
  }

  Future<void> _initLocalNotification() async {
    // IMPORTANT: resource names here MUST match files you add in android/app/src/main/res/drawable or mipmap.
    // Use resource name WITHOUT the '@drawable/' prefix.
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('launcher_icon'); // <- resource name (small icon)

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

    // Vibration pattern as Int64List
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
      _showLocalNotificationFromRemote(msg);

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
      controller.currentIndex.value = 3;
    });
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('getInitialMessage: ${initialMessage.data}');
      if (_isSafetyCheckin(initialMessage.data)) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _handleSafetyCheckInNotification(initialMessage.data);
        });
      } else {
        controller.currentIndex.value = 3;
      }
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
    final checkInId = data['checkInId']?.toString() ?? data['check_in_id']?.toString() ?? '0';
    print('Handling safety check-in: $checkInId');

    // If dialog is already open, avoid opening again
    if (Get.isDialogOpen ?? false) {
      return;
    }

    // Cancel any existing safety notification before opening dialog
    NotificationServices.cancelSafetyNotification();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!(Get.isDialogOpen ?? false)) {
        Get.dialog(SosCheckInDialog(checkInId: checkInId), barrierDismissible: false, name: 'SosCheckInDialog');
      }
    });
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

    controller.currentIndex.value = 3;
  }

  static Map<String, dynamic> _stringToMap(String payload) {
    try {
      return Map<String, dynamic>.from(jsonDecode(payload));
    } catch (_) {
      return {};
    }
  }

  Future<void> _showLocalNotificationFromRemote(RemoteMessage message) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        safetyChannelId,
        safetyChannelName,
        channelDescription: safetyChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('safety_alert'),
        // Use resource name WITHOUT '@' prefix
        icon: 'launcher_icon',
        // Provide tag so Android replaces previous safety notifications
        tag: _isSafetyCheckin(message.data) ? safetyAndroidTag : null,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableVibration: true,
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
      final body = message.notification?.body ?? message.data['body'] ?? 'Please responce to sefety checkin';

      final notificationId = _isSafetyCheckin(message.data) ? safetyNotificationId : generalNotificationId;

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: jsonEncode(message.data.isNotEmpty ? message.data : {'message': 'no-data'}),
      );
    } catch (e) {
      print('Error showing local notification from remote: $e');
    }
  }

  // Background isolate helper
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    try {
      if (_isSafetyCheckin(message.data)) {
        await _flutterLocalNotificationsPlugin.cancel(safetyNotificationId);
      }

      final FlutterLocalNotificationsPlugin plugin = _flutterLocalNotificationsPlugin;

      // Use same resource names as init
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('launcher_icon');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
      final settings = InitializationSettings(android: androidInit, iOS: iosInit);

      await plugin.initialize(settings);

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

      await plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(safetyChannel);

      final androidDetails = AndroidNotificationDetails(
        safetyChannelId,
        safetyChannelName,
        channelDescription: safetyChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('safety_alert'),
        icon: 'launcher_icon',
        tag: _isSafetyCheckin(message.data) ? safetyAndroidTag : null,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableVibration: true,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'safety_alert.mp3',
        threadIdentifier: iosThreadIdentifier,
      );

      final notifDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails);

      final title = message.notification?.title ?? message.data['title'] ?? 'Safety Alert';
      final body = message.notification?.body ?? message.data['body'] ?? 'Please respond to safety checkin';

      final notificationId = _isSafetyCheckin(message.data) ? safetyNotificationId : generalNotificationId;

      await plugin.show(
        notificationId,
        title,
        body,
        notifDetails,
        payload: jsonEncode(message.data.isNotEmpty ? message.data : {'message': 'no-data'}),
      );

      print('Background notification shown');
    } catch (e) {
      print('Error in showBackgroundNotification: $e');
    }
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

  static Future<void> cancelSafetyNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(safetyNotificationId);
    print('Safety notification cancelled');
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('All notifications cancelled');
  }
}
