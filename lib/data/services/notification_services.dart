import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/navigation_controller.dart';
import 'package:security_guard/shared/widgets/sos_checkIn_dialog.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BottomNavController controller = Get.put(BottomNavController());

  // bool _tokenSentToBackend = false;

  Future<void> initialize() async {
    try {
      // Initialize local notifications first
      initLocalNotification();

      // Request notification permissions
      requestNotificationPermission();

      // Initialize Firebase messaging handlers
      firebaseInit();

      // Set up token refresh listener
      messaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed:😊😊😊 $newToken');
      });
  
    } catch (e) {
      print('Error initializing notification services: $e');
      // Continue app execution even if notification setup fails
    }
  }

  Future<void> initLocalNotification() async {
    try {
      // Android initialization settings with custom launcher icon
      var androidInitializationSettings = const AndroidInitializationSettings(
        "@drawable/launcher_icon", // Custom launcher icon for notifications
      );

      // iOS initialization settings with all permissions explicitly requested
      var iosInitializationSettings = const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      // Combined initialization settings
      var initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (payload) {
          // Handle notification tap
          handleNotificationTap(payload);
        },
      );

      // For iOS, request permissions explicitly again to ensure they're granted
      if (GetPlatform.isIOS) {
        // On iOS, we need to request permissions directly through Firebase Messaging
        // as the local notifications plugin might not have the correct implementation

        // Enable system foreground notifications for iOS
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true, // Show alert
              badge: true, // Update badge
              sound: true, // Play sound
            );

        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: true,
        );
      }

      print('Local notifications initialized successfully');
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  void handleNotificationTap(NotificationResponse? payload) {
    if (payload != null && payload.payload != null) {
      print('Notification tapped with payload: ${payload.payload}');

      try {
        // Parse the payload as JSON
        final data = jsonDecode(payload.payload!);

        // Check if it's a safety check-in notification
        if (data['Type'] == 'safety_checkin') {
          handleSafetyCheckInNotification(data);
          return;
        }
      } catch (e) {
        print('Error parsing notification payload: $e');
      }

      // Handle other notifications (your existing logic)
      controller.currentIndex.value = 3;
    }
  }

  // Add this method to handle safety check-in specific notifications
  void handleSafetyCheckInNotification(Map<String, dynamic> data) {
    if (data['Type'] == 'safety_checkin') {
      final checkInId = data['checkInId'];
      final sender = data['sender'];

      print('Safety check-in notification received: ID $checkInId');

      // Navigate to main screen if needed and show dialog
      // if (Get.currentRoute != '/home') {
      //   Get.offAllNamed('/home');
      // }

      // Small delay to ensure navigation completes
      Future.delayed(const Duration(milliseconds: 300), () {
        _showSafetyCheckInDialog(checkInId);
      });
    }
  }

  void _showSafetyCheckInDialog(String checkInId) {
    // Close any existing dialogs first
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    Get.dialog(
      SosCheckInDialog(checkInId: checkInId),
      barrierDismissible: false,
      name: 'SosCheckInDialog',
    );
  }

  void firebaseInit() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      print('Got a message in the foreground!');
      print('Message data: ${message.data}');

      // Check if it's a safety check-in notification
      if (message.data['Type'] == 'safety_checkin') {
        // For foreground, show dialog immediately without notification
        handleSafetyCheckInNotification(message.data);
        return;
      }

      // For other notifications, show notification
      if (!GetPlatform.isIOS) {
        showNotification(message);
      }
    });

    // Handle notification clicks when app is in background but open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A notification was clicked on: ${message.data}');

      // Check if it's a safety check-in notification
      if (message.data['Type'] == 'safety_checkin') {
        handleSafetyCheckInNotification(message.data);
        return;
      }

      // Handle other notifications (your existing logic)
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    try {
      // Create a unique channel ID for Android
      AndroidNotificationChannel channel = AndroidNotificationChannel(
        Random.secure().nextInt(100000).toString(),
        "High Importance Notifications",
        importance: Importance.max,
        enableVibration: true, // Enable vibration
        playSound: true, // Enable sound
      );

      AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            channel.id.toString(),
            channel.name.toString(),
            channelDescription: "Your channel description",
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@drawable/launcher_icon', // Custom launcher icon
            largeIcon: const DrawableResourceAndroidBitmap(
              '@drawable/launcher_icon',
            ),
            sound: const RawResourceAndroidNotificationSound(
              'notification_sound',
            ), // Custom sound (optional)
            enableVibration: true,
            vibrationPattern: Int64List.fromList([
              0,
              1000,
              500,
              1000,
            ]), // Custom vibration pattern
            enableLights: true,
            ledColor: const Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
            playSound: true,
          );

      // Configure iOS notification details with all presentation options enabled
      // Make sure all presentation options are explicitly set to true
      DarwinNotificationDetails darwinNotificationDetails =
          const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default', // You can use custom sound file name here
            badgeNumber: 1,
          );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      // For debugging
      print(
        'Showing notification on platform: ${GetPlatform.isIOS ? 'iOS' : 'Android'}',
      );

      // Generate a unique ID for each notification
      int notificationId = Random().nextInt(1000000);

      // Check if notification is not null
      if (message.notification != null) {
        // Show notification using the local notifications plugin
        await _flutterLocalNotificationsPlugin.show(
          notificationId,
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? '',
          notificationDetails,
          payload: message.data.toString(),
        );

        print('Notification shown with ID: $notificationId');
      } else if (message.data.isNotEmpty) {
        // Handle data-only messages
        await _flutterLocalNotificationsPlugin.show(
          notificationId,
          message.data['title'] ?? 'New Notification',
          message.data['body'] ?? '',
          notificationDetails,
          payload: message.data.toString(),
        );

        print('Data notification shown with ID: $notificationId');
      }
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission: ${settings.authorizationStatus}');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print(
        'User granted provisional permission: ${settings.authorizationStatus}',
      );
    } else {
      print(
        'User declined or have not accepted permission: ${settings.authorizationStatus}',
      );
    }
  }
   Future<String?> getDeviceToken() async {
    try {
      // For iOS, we need to get the APNS token first
      if (GetPlatform.isIOS) {
        // Get the APNs token first
        String? apnsToken = await messaging.getAPNSToken();
        print('APNS Token: $apnsToken');

        // For iOS, we'll try to get the FCM token even if APNS token is null
        // This is because in some cases, the FCM token might be available
        // even when the APNS token is not yet available
        String? token = await messaging.getToken();
        print('iOS FCM Token: $token');

        // If we got a token, return it
        if (token != null && token.isNotEmpty) {
          return token;
        } else {
          print('FCM token not available yet for iOS. Will retry later.');

          // Set up a one-time listener for when the token becomes available
          // This is in addition to the onTokenRefresh listener
          Future.delayed(const Duration(seconds: 2), () async {
            String? delayedToken = await messaging.getToken();
            if (delayedToken != null && delayedToken.isNotEmpty) {
              print('Delayed FCM token now available: $delayedToken');
              // sendTokenToBackend(delayedToken);
            }
          });

          return null;
        }
      } else {
        // For Android and other platforms, directly get the FCM token
        String? token = await messaging.getToken();
        print('Android FCM Token: $token');
        return token;
      }
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  // Optional: Method to configure topic subscriptions
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
