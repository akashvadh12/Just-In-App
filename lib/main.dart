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
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

// Global flag to prevent multiple Firebase initializations
bool _firebaseInitialized = false;

// Updated background handler with proper Firebase check
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.data}');
  
  // Only initialize Firebase if not already initialized
  if (!_firebaseInitialized) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _firebaseInitialized = true;
    } catch (e) {
      print('Firebase already initialized in background handler: $e');
    }
  }
  
  // Use the static method from NotificationServices
  await NotificationServices.showBackgroundNotification(message);
  
  // Store notification data for when app opens
  try {
    final prefs = await SharedPreferences.getInstance();
    if (message.data.isNotEmpty) {
      await prefs.setString('pending_notification', jsonEncode(message.data));
    }
  } catch (e) {
    print('Error storing pending notification: $e');
  }
}

// Headless task - moved outside with better error handling
@pragma('vm:entry-point')
void headlessTask(bg.HeadlessEvent headlessEvent) async {
  print('[BackgroundGeolocation HeadlessTask]: $headlessEvent');
  
  try {
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
  } catch (e) {
    print('Error in headless task: $e');
  }
}

void main() async {
  // Ensure widgets binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase once and only once
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _firebaseInitialized = true;
    print('Firebase initialized successfully');
    
    // Set the background message handler AFTER Firebase initialization
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize services in proper order with error handling
    await initServices();
    print('All services initialized successfully');
    
  } catch (e) {
    print('Critical error during app initialization: $e');
    // You might want to show an error screen here instead of crashing
  }
  
  // Run the app
  runApp(MyApp());
  
  // Register headless task AFTER app is running
  try {
    bg.BackgroundGeolocation.registerHeadlessTask(headlessTask);
    print('Background geolocation headless task registered');
  } catch (e) {
    print('Error registering headless task: $e');
  }
}

// Improved service initialization with proper order and error handling
Future<void> initServices() async {
  print('Starting services initialization...');

  try {
    // 1. Initialize core storage service first (other services depend on this)
    await Get.putAsync(() => LocalStorageService().init(), permanent: true);
    print('✓ LocalStorageService initialized');
    
    // 2. Initialize notification service early (needed for background handlers)
    final notificationService = NotificationServices();
    await notificationService.initialize();
    Get.put(notificationService, permanent: true);
    print('✓ NotificationServices initialized');
    
    // 3. Initialize connectivity controller
    Get.put(ConnectivityController(), permanent: true);
    print('✓ ConnectivityController initialized');
    

       // 5. Initialize session service
    Get.put(SessionService(), permanent: true);
    print('✓ SessionService initialized');
    
    // 4. Initialize API services
    Get.put(ApiGetServices(), permanent: true);
    Get.put(ApiService(), permanent: true);
    print('✓ API Services initialized');
    
 
    
    // 6. Initialize controllers that depend on other services
    Get.put(ProfileController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    print('✓ Controllers initialized');
    
    // 7. Initialize specialized services last
    Get.put(SosCheckInService(), permanent: true);
    Get.put(AppLifecycleService(), permanent: true);
    print('✓ Specialized services initialized');
    
    print('All services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
    // Don't rethrow - let app continue with partial initialization
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
      onReady: () async {
        print('App is fully ready');
        // Handle any pending notifications with delay to ensure everything is ready
        await Future.delayed(const Duration(milliseconds: 500));
        _handlePendingNotifications();
      },
    );
  }

  // Improved pending notifications handler
  void _handlePendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('pending_notification');
      
      if (storedData != null) {
        final data = Map<String, dynamic>.from(jsonDecode(storedData));
        await prefs.remove('pending_notification');
        
        print('Found pending notification: $data');
        
        // Handle safety checkin notifications
        if (data['Type'] == 'safety_checkin' || 
            data['type'] == 'safety_checkin' || 
            data['event'] == 'safety_checkin') {
          
          // Cancel any existing notifications
          NotificationServices.cancelSafetyNotification();
          
          // Wait for UI to be fully ready
          await Future.delayed(const Duration(milliseconds: 1000));
          
          final checkInId = data['checkInId']?.toString() ?? 
                           data['check_in_id']?.toString() ?? '0';
          
          // Only show dialog if no dialog is currently open
          if (!(Get.isDialogOpen ?? false)) {
            // Uncomment when SosCheckInDialog is ready
            // Get.dialog(
            //   SosCheckInDialog(checkInId: checkInId),
            //   barrierDismissible: false,
            //   name: 'SosCheckInDialog',
            // );
          }
        }
      }
    } catch (e) {
      print('Error handling pending notifications: $e');
    }
  }
}
