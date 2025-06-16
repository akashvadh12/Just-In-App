import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/api/api_service.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/modules/auth/controllers/auth_controller.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync(() => LocalStorageService().init());
  await initServices();
  Get.put(ProfileController());
  Get.put(AuthController());
  

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
