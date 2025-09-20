// lib/notification_services.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

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

  // Use a fixed channel id — backend should also use this channel_id for best results
  static const String safetyChannelId = 'safety_checkin_channel';
  static const String safetyChannelName = 'Safety Check-In';
  static const String safetyChannelDescription = 'Safety check-in alerts';

  /// Call this from main() after Firebase.initializeApp()
  Future<void> initialize() async {
    try {
      await _initLocalNotification();
      await _requestPermissions();

      // Handle token refresh for logging/debugging (optionally send to backend)
      _messaging.onTokenRefresh.listen((token) {
        print('FCM token refreshed: $token');
      });

      // Foreground & opened app handlers
      _setupFirebaseHandlers();

      // Optionally handle initial message (when app opened from terminated state)
      _checkInitialMessage();
    } catch (e, st) {
      print('NotificationServices.initialize error: $e\n$st');
    }
  }

  // ------------------ Internal init ------------------
  Future<void> _initLocalNotification() async {
    // Android: create channel with custom sound & vibration
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/launcher_icon');

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
        // Handle user tapping notification
        _handleNotificationResponse(response);
      },
    );

    // Create Android notification channel with sound and vibration pattern
     Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

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

    // iOS: set foreground presentation options (we will explicitly request permission separately)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    print('Local notifications initialized');
  }

  Future<void> _requestPermissions() async {
    // Request permissions via Firebase Messaging (covers both iOS and Android)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true, // only works if entitlement given; harmless otherwise
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  void _setupFirebaseHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      print('onMessage: ${msg.data}');

      if (_isSafetyCheckin(msg.data)) {
        // For foreground: show the dialog immediately (with small delay)
        _handleSafetyCheckInNotification(msg.data);
        return;
      }

      // For other messages — show local notification (so sound/vibrate works same as background)
      _showLocalNotificationFromRemote(msg);
    });

    // When a user taps notification and app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      print('onMessageOpenedApp: ${msg.data}');
      if (_isSafetyCheckin(msg.data)) {
        _handleSafetyCheckInNotification(msg.data);
        return;
      }

      // Put any other navigation logic here
      controller.currentIndex.value = 3;
    });
  }

  Future<void> _checkInitialMessage() async {
    // When app is opened from a terminated state by a notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('getInitialMessage: ${initialMessage.data}');
      if (_isSafetyCheckin(initialMessage.data)) {
        // small delay to ensure UI is ready
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
    // parse checkInId
    final checkInId = data['checkInId']?.toString() ?? data['check_in_id']?.toString() ?? '0';
    print('Handling safety check-in: $checkInId');

    // Ensure any open dialogs closed
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    // Show dialog
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.dialog(SosCheckInDialog(checkInId: checkInId), barrierDismissible: false, name: 'SosCheckInDialog');
    });
  }

  // Called when user taps notification (local notification plugin callback)
  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final Map<String, dynamic> data = _stringToMap(payload);
        
        print('Notification tapped with payload:🔴🔴🔴🔴========================> $data');
        if (_isSafetyCheckin(data)) {
          _handleSafetyCheckInNotification(data);
          return;
        }
      } catch (e) {
        print('Error parsing payload: $e');
      }
    }

    // default action
    controller.currentIndex.value = 3;
  }

  // Helper to safely parse payloads that might be a map or string
  static Map<String, dynamic> _stringToMap(String payload) {
    // If payload looks like a Map (from toString) try to parse, else json decode
    try {
      return Map<String, dynamic>.from(jsonDecode(payload));
    } catch (_) {
      // Try naive parsing: replace equals/=> then basic conversion (fallback)
      // But prefer backend to send JSON string in payload
      return {};
    }
  }

  // Show a local notification for remote message (used on foreground)
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
        icon: '@drawable/launcher_icon',
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/launcher_icon'),
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableVibration: true,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'safety_alert.wav',
        // interruptionLevel: NotificationInterruptionLevel.critical, // will be ignored without entitlement
      );

      final platformDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails);

      final title = message.notification?.title ?? message.data['title'] ?? 'Alert';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      await _flutterLocalNotificationsPlugin.show(
        Random().nextInt(1000000),
        title,
        body,
        platformDetails,
        payload: jsonEncode(message.data.isNotEmpty ? message.data : {'message': 'no-data'}),
      );
    } catch (e) {
      print('Error showing local notification from remote: $e');
    }
  }

  // ---------- Public helper: used by background isolate ----------
  /// This static method is used by the background isolate handler to show a notification
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    try {
      // Ensure plugin initialized in background isolate
      final FlutterLocalNotificationsPlugin plugin = _flutterLocalNotificationsPlugin;

      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@drawable/launcher_icon');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
      final settings = InitializationSettings(android: androidInit, iOS: iosInit);

      await plugin.initialize(settings);

      // Android channel creation (again in background isolate)
       Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

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
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableVibration: true,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'safety_alert.wav',
        // interruptionLevel: NotificationInterruptionLevel.critical,
      );

      final notifDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails);

      final title = message.notification?.title ?? message.data['title'] ?? 'Safety Alert';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      await plugin.show(
        Random().nextInt(1000000),
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

  // Public utility to fetch FCM token
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

  // Topic subscription helpers
  Future<void> subscribeToTopic(String t) => _messaging.subscribeToTopic(t);
  Future<void> unsubscribeFromTopic(String t) => _messaging.unsubscribeFromTopic(t);
}
