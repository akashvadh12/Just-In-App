import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';

class AuthController extends GetxController {
  final TextEditingController credentialsController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  final RxBool isLoading = false.obs;
  final RxBool isSendingOTP = false.obs;
  
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
    
    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      isLoading.value = false;
      Get.snackbar(
        'Success', 
        'Login successful!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );
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
  
  @override
  void onClose() {
    credentialsController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}