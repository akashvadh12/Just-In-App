import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/api/api_service.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/firebase_options.dart';
import 'package:security_guard/modules/auth/controllers/auth_controller.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/routes/app_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
   
  final prefs = await SharedPreferences.getInstance();
  if (message.data.isNotEmpty) {
    await prefs.setString('pending_notification', jsonEncode(message.data));
  } else {
    await prefs.setBool('received_notification', true);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("firebase initialized 😁😁😁😊");
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Get.putAsync(() => LocalStorageService().init());
  await initServices();
  Get.put(ConnectivityController());
  Get.put(ProfileController());
  Get.put(AuthController());
  _setupNotificationHandlers();

  runApp(MyApp());
}

Future<void> initServices() async {
  print('Starting services initialization...');

  try {
    await Get.putAsync(() => LocalStorageService().init(), permanent: true);
    print('All services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
  }
}

  Future<void> _setupNotificationHandlers() async {
    try {
      // Request permission with full options
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      // For iOS, ensure foreground notifications are enabled
      if (GetPlatform.isIOS) {
        // We don't need to set presentation options here anymore
        // as we're handling notifications through our notification service

        print('Requesting APNS token for iOS device');
        // This will trigger the APNS token request
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        print('Initial APNS token: $apnsToken');
      }

      // Set up message handlers
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from background notification');
        _handleNotificationNavigation();
      });

      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        // App was opened from notification while terminated
        print('App opened from terminated notification');
        _handleNotificationNavigation();
      } else {
        // Check if we have stored notification data
        final prefs = await SharedPreferences.getInstance();
        final hasPendingNotification =
            prefs.containsKey('pending_notification') ||
            prefs.getBool('received_notification') == true;

        if (hasPendingNotification) {
          await prefs.remove('pending_notification');
          await prefs.remove('received_notification');

          // Schedule navigation after app is initialized
          Future.delayed(Duration(seconds: 1), () {
            _handleNotificationNavigation();
          });
        }
      }
    } catch (e) {
      print('Error setting up notification handlers: $e');
      // Continue app execution even if notification setup fails
    }
  }

  void _handleNotificationNavigation() {
    final authController = Get.find<AuthController>();
    // if (authController.isUserSignedIn())
    //  {
    //   if (Get.currentRoute != '/home/notification') {
    //     // Get.to(NotificationScreen());
    //     // Get.find<NotificationController>().fetchNotifications();
    //   }
    // }
  }


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: BindingsBuilder(() {
        Get.put(ApiService());
      }),
      title: 'Just IN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
      ),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
