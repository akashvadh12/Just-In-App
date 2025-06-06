import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/api/api_service.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/modules/attandance/AttendanceHistoryScreen/AttendanceHistoryScreen.dart';

import 'package:security_guard/modules/auth/ForgotPassword/forgot_password_controller.dart';
import 'package:security_guard/modules/auth/controllers/auth_controller.dart';
import 'package:security_guard/modules/auth/login/login_page.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:security_guard/modules/issue/issue_list/issue_view/issue_screen.dart' hide AppColors;
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';
import 'package:security_guard/modules/notification/notification_screen.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/modules/profile/Profile_screen.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/routes/app_pages.dart';
import 'package:security_guard/routes/app_rout.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/bottomnavigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync(() => LocalStorageService().init());

  // Initialize services before running the app
  await initServices();
  Get.put(AuthController());

  runApp(MyApp());
}

// Initialize all essential services
Future<void> initServices() async {
  print('Starting services initialization...');

  try {
    // Initialize LocalStorageService first
    await Get.putAsync(() => LocalStorageService().init(), permanent: true);

    // You can initialize other services here as well
    // Example:
    // await Get.putAsync(() => SomeOtherService().init(), permanent: true);

    print('All services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
    // Handle initialization errors gracefully
  }
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
      initialRoute: AppPages.INITIAL ,
      // home: BottomNavBarWidget(),
      getPages: AppPages.routes,
      // Uncomment these if you want to use routes
      // initialRoute: AppPages.INITIAL,
      // getPages: AppPages.routes,
      // initialBinding: BindingsBuilder(() {
      //   Get.put(AuthController());
      //   Get.put(ForgotPasswordController());
      // }),
    );
  }
}

class RootScreen extends StatelessWidget {
  RootScreen({Key? key}) : super(key: key);

  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    authController.checkLoginStatus();

    return Obx(() {
      return authController.isLoggedIn.value
          ? BottomNavBarWidget() // User logged in, show main app
          : LoginPage(); // Not logged in, show login screen
    });
  }
}
