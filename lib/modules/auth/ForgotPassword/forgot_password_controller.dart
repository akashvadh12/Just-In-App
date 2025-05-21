import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';

// Controller for the Forgot Password screen
class ForgotPasswordController extends GetxController {
  final phoneOrEmployeeId = ''.obs;
  final newPassword = ''.obs;
  final confirmPassword = ''.obs;
  final countdown = 30.obs;
  final isCodeSent = false.obs;
  final verificationCode = ['', '', '', '', '', ''].obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // Text editing controllers for the verification code fields
  final List<TextEditingController> codeControllers = 
      List.generate(6, (_) => TextEditingController());

  // Focus nodes for the verification code fields
  final List<FocusNode> codeFocusNodes = 
      List.generate(6, (_) => FocusNode());

  @override
  void onClose() {
    // Dispose of controllers and focus nodes
    for (var controller in codeControllers) {
      controller.dispose();
    }
    for (var focusNode in codeFocusNodes) {
      focusNode.dispose();
    }
    super.onClose();
  }

  void sendResetCode() {
    if (phoneOrEmployeeId.value.isEmpty) {
      Get.snackbar(
        'Error', 
        'Please enter your phone number or employee ID',
        backgroundColor: AppColors.error,
        colorText: AppColors.whiteColor,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Send reset code logic would go here
    isCodeSent.value = true;
    
    // Reset and start countdown
    countdown.value = 30;
    startCountdown();
  }

  void startCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (countdown.value > 0) {
        countdown.value--;
        startCountdown();
      }
    });
  }

  void resendCode() {
    if (countdown.value > 0) return;
    
    // Logic to resend the code
    countdown.value = 30;
    startCountdown();
  }

  void updateVerificationCode(int index, String value) {
    final newCode = [...verificationCode];
    newCode[index] = value;
    verificationCode.value = newCode;
    
    // Auto-focus to next field
    if (value.isNotEmpty && index < 5) {
      codeFocusNodes[index + 1].requestFocus();
    }
  }

  bool validatePassword() {
    return newPassword.value.length >= 8 &&
           RegExp(r'[A-Z]').hasMatch(newPassword.value) &&
           RegExp(r'[0-9]').hasMatch(newPassword.value) &&
           RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword.value);
  }

  bool validatePasswords() {
    return validatePassword() && 
           confirmPassword.value == newPassword.value;
  }

  void setNewPassword() {
    if (!validatePasswords()) {
      Get.snackbar(
        'Error', 
        'Please check your password requirements',
        backgroundColor: AppColors.error,
        colorText: AppColors.whiteColor,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Set new password logic would go here
    Get.snackbar(
      'Success', 
      'Your password has been reset successfully',
      backgroundColor: AppColors.greenColor,
      colorText: AppColors.whiteColor,
      snackPosition: SnackPosition.BOTTOM,
    );
    
    // Navigate back to login
    Future.delayed(Duration(seconds: 2), () {
      Get.back();
    });
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }
}