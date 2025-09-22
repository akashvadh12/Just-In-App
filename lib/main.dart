import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/api/api_service.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/data/services/app_lifecycle_service.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/data/services/notification_services.dart';
import 'package:security_guard/data/services/session_service.dart';
import 'package:security_guard/data/services/sos_checkin_service.dart';
import 'package:security_guard/firebase_options.dart';
import 'package:security_guard/modules/auth/controllers/auth_controller.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/routes/app_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

// Updated background handler to use the static method with fixed IDs
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.data}');
  
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Use the static method from NotificationServices to show notification with fixed ID
  await NotificationServices.showBackgroundNotification(message);
  
  // Store notification data for when app opens (backup for killed state)
  final prefs = await SharedPreferences.getInstance();
  if (message.data.isNotEmpty) {
    await prefs.setString('pending_notification', jsonEncode(message.data));
  }
}

// In main.dart - OUTSIDE any class
void headlessTask(bg.HeadlessEvent headlessEvent) async {
  print('[BackgroundGeolocation HeadlessTask]: $headlessEvent');
  
  switch(headlessEvent.name) {
    case bg.Event.LOCATION:
      bg.Location location = headlessEvent.event;
      print('- Headless Location: $location');
      break;
      
    case bg.Event.HTTP:
      bg.HttpEvent response = headlessEvent.event;
      print('- Headless HTTP Response: $response');
      break;
      
    case bg.Event.TERMINATE:
      bg.State state = headlessEvent.event;
      print('- App terminated: $state');
      break;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await initServices();
  Get.put(SessionService());
  Get.put(ApiGetServices());
  Get.put(ConnectivityController());
  Get.put(ProfileController());
  Get.put(AuthController());
  Get.put(SosCheckInService());
  Get.put(AppLifecycleService());
  
  // Initialize notification services
  final notificationService = NotificationServices();
  await notificationService.initialize();
  Get.put(notificationService); 
  
  
  runApp(MyApp());
  bg.BackgroundGeolocation.registerHeadlessTask(headlessTask);
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

// REMOVED: All notification handling functions - let NotificationServices handle

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
      // Add this to ensure app is fully ready before handling notifications
      onReady: () {
        print('App is fully ready');
        // Check for any pending notifications stored during killed state
        // _handlePendingNotifications();
      },
    );
  }

  // Handle any notifications stored when app was killed
  void _handlePendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('pending_notification');
      
      if (storedData != null) {
        final data = Map<String, dynamic>.from(jsonDecode(storedData));
        await prefs.remove('pending_notification');
        
        print('Found pending notification: $data');
        
        // Use the NotificationServices to handle this properly
        final notificationService = Get.find<NotificationServices>();
        if (data['Type'] == 'safety_checkin' || 
            data['type'] == 'safety_checkin' || 
            data['event'] == 'safety_checkin') {
          
          // Cancel any existing notifications
          NotificationServices.cancelSafetyNotification();
          
          // Wait a bit more to ensure everything is ready, then show dialog
          Future.delayed(const Duration(milliseconds: 1000), () {
            final checkInId = data['checkInId']?.toString() ?? 
                             data['check_in_id']?.toString() ?? '0';
            
            // if (!(Get.isDialogOpen ?? false)) {
            //   Get.dialog(
            //     SosCheckInDialog(checkInId: checkInId),
            //     barrierDismissible: false,
            //     name: 'SosCheckInDialog',
            //   );
            // }
          });
        }
      }
    } catch (e) {
      print('Error handling pending notifications: $e');
    }
  }
}
