import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/modules/auth/ForgotPassword/forgot_password_view.dart';

class AuthController extends GetxController {
  final TextEditingController credentialsController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  final RxBool isLoading = false.obs;
  final RxBool isSendingOTP = false.obs;
  final RxBool isLoginMode = true.obs; // Track login/signup mode

  final RxBool isLoggedIn = false.obs; // New: Track if user is logged in

  /// Simulated check login status (could be replaced with real local storage check)
  Future<void> checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 1));
    // For demo, assuming user is logged out by default
    isLoggedIn.value = false;

    // TODO: Replace above with real check:
    // Example: isLoggedIn.value = await yourStorage.hasValidToken();
  }

  /// Call this after successful login/signup
  void setLoggedIn(bool status) {
    isLoggedIn.value = status;
  }

  void toggleMode() {
    isLoginMode.toggle();
    credentialsController.clear();
    passwordController.clear();
  }
  
  void login() {
    if (credentialsController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error', 
        'Please enter your credentials and password/OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }
    
    isLoading.value = true;
    
    // Simulate API call for login
    Future.delayed(Duration(seconds: 2), () {
      isLoading.value = false;
      // On success:
      setLoggedIn(true);

      Get.snackbar(
        'Success', 
        isLoginMode.value ? 'Login successful!' : 'Signup successful!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );

      // Navigate to main app screen after login (optional)
      // Get.offAll(() => BottomNavBarWidget()); // Import this if used here
    });
  }
  
  void sendOTP() {
    if (credentialsController.text.isEmpty) {
      Get.snackbar(
        'Error', 
        'Please enter your phone number or employee ID first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }
    
    isSendingOTP.value = true;
    
    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      isSendingOTP.value = false;
      Get.snackbar(
        'Success', 
        'OTP sent successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.greenColor,
        colorText: Colors.white,
      );
    });
  }
  
  void navigateToForgotPassword() {
    Get.to(() => ForgotPasswordView());
  }

  /// Log the user out
  void logout() {
    isLoggedIn.value = false;
    credentialsController.clear();
    passwordController.clear();
    // You can also clear saved tokens/local storage here
    // Then navigate to login screen
    // Get.offAll(() => GuardAttendanceScreen());
  }
  
  @override
  void onClose() {
    credentialsController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
