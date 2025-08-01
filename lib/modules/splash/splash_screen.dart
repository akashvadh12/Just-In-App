import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/routes/app_rout.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Add a small delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    try {
      final storage = LocalStorageService.instance;
      final deviceToken = storage.getDeviceToken();

      if (deviceToken != null && deviceToken.isNotEmpty) {
        // Device token exists, navigate to main app
        Get.offAllNamed(Routes.BOTTOM_NAV);
      } else {
        // Device token does not exist, navigate to login
        // Get.offAllNamed(Routes.BOTTOM_NAV);
        Get.offAllNamed(Routes.LOGIN);
      }
    } catch (e) {
      print('Error checking login status: $e');
      // On error, navigate to login
      Get.offAllNamed(Routes.BOTTOM_NAV);
      // Get.offAllNamed(Routes.LOGIN);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'lib/assets/Just-IN.jpeg', // Replace with your actual image path
                height: 60,
                width: 60,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 24),
            // App Title
            Text(
              'JustIN',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            // App Subtitle
            Text(
              'Secure Access for Security Professionals',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
