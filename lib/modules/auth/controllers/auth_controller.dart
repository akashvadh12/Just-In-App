import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/data/services/api_post_service.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/routes/app_rout.dart';
import 'package:security_guard/shared/widgets/Custom_Snackbar/Custom_Snackbar.dart';

class AuthController extends GetxController {
  // Controllers
  final credentialsController = TextEditingController();
  final passwordController = TextEditingController();

  // Reactive variables
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;
  final isSendingOTP = false.obs;
  final isLoginMode = true.obs;
  final isLoggedIn = false.obs;
  final loginWithPhone = false.obs;

  // Services
  final ApiPostServices _apiService = ApiPostServices();
  final LocalStorageService _storage = LocalStorageService.instance;
  final ProfileController profileController = Get.find<ProfileController>();

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  // Toggle methods
  void togglePasswordVisibility() => isPasswordHidden.toggle();

  void toggleLoginMethod() {
    loginWithPhone.toggle();
    clearFields();
  }

  void toggleMode() {
    isLoginMode.toggle();
    clearFields();
  }

  void clearFields() {
    credentialsController.clear();
    passwordController.clear();
  }

  /// Check if user is already logged in
  Future<void> checkLoginStatus() async {
    try {
      // Only check for device token, not login status in storage
      final deviceToken = _storage.getDeviceToken();
      final loggedIn = deviceToken != null && deviceToken.isNotEmpty;
      isLoggedIn.value = loggedIn;
      if (loggedIn) {
        log('✅ User is already logged in');
        Get.offAllNamed(Routes.BOTTOM_NAV);
      }
    } catch (e) {
      log('❌ Error checking login status: $e');
      isLoggedIn.value = false;
    }
  }

  /// Set login status
  void setLoggedIn(bool status) {
    isLoggedIn.value = status;
  }

  /// Main login method using ApiPostServices
  Future<void> login() async {
    final input = credentialsController.text.trim();
    final password = passwordController.text.trim();

    // Validation
    if (!_validateInput(input, password)) return;

    isLoading.value = true;

    try {
      log(
        '🔐 Attempting login with ${loginWithPhone.value ? 'phone' : 'username'}: $input',
      );

      // Use centralized API service
      final response = await _apiService.login(
        input: input,
        password: password,
        loginWithPhone: loginWithPhone.value,
      );

      await _handleLoginResponse(response);
    } catch (e) {
      log('❌ Login error: $e');
      _showErrorSnackbar('Login failed. Please try again later.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate login input
  bool _validateInput(String input, String password) {
    if (input.isEmpty || password.isEmpty) {
      _showErrorSnackbar(
        'Please enter your ${loginWithPhone.value ? 'phone number' : 'user ID'} and password.',
      );
      return false;
    }

    // Additional phone number validation
    if (loginWithPhone.value && !_isValidPhoneNumber(input)) {
      _showErrorSnackbar('Please enter a valid phone number.');
      return false;
    }

    return true;
  }

  /// Simple phone number validation
  bool _isValidPhoneNumber(String phone) {
    final phoneRegExp = RegExp(r'^\+?[\d\s-()]{8,15}$');
    return phoneRegExp.hasMatch(phone);
  }

  /// Handle login API response
  Future<void> _handleLoginResponse(Map<String, dynamic> response) async {
    try {
      if (response['status'] == true &&
          response['userInf'] != null &&
          (response['userInf'] as List).isNotEmpty) {
        final userData = response['userInf'][0] as Map<String, dynamic>;
        final name = userData['name'] ?? 'User';
        final deviceToken = userData['deviceToken'] ?? '';

        profileController.userModel.value = UserModel.fromJson(
          response['userInf'][0],
        );

        await _storage.saveUserId(userData['userID'] ?? '');

        if (deviceToken.isNotEmpty) {
          await _storage.saveDeviceToken(deviceToken);
        }

        setLoggedIn(true);
        log('✅ Login successful for user: $name');
        _showSuccessSnackbar('Welcome, $name!');
        Get.offAllNamed(Routes.BOTTOM_NAV);
      } else {
        final errorMessage =
            response['message'] ??
            'Invalid ${loginWithPhone.value ? 'phone number' : 'user ID'} or password.';
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      log('❌ Error handling login response: $e');
      _showErrorSnackbar('An error occurred while processing login.');
    }
  }

  /// Send OTP (placeholder implementation)
  Future<void> sendOTP() async {
    final phone = credentialsController.text.trim();

    if (phone.isEmpty) {
      _showErrorSnackbar('Please enter your phone number first.');
      return;
    }

    if (!_isValidPhoneNumber(phone)) {
      _showErrorSnackbar('Please enter a valid phone number.');
      return;
    }

    isSendingOTP.value = true;

    try {
      // TODO: Implement actual OTP API call using _apiService
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      log('📱 OTP sent to: $phone');
      _showSuccessSnackbar('OTP sent successfully!');
    } catch (e) {
      log('❌ OTP sending failed: $e');
      _showErrorSnackbar('Failed to send OTP. Please try again.');
    } finally {
      isSendingOTP.value = false;
    }
  }

  /// Navigate to forgot password screen
  void navigateToForgotPassword() {
    Get.toNamed(Routes.FORGOT_PASSWORD);
  }

  /// Logout user
  Future<void> logout() async {
    try {
      log('🚪 Logging out user');
      await _storage.removeDeviceToken();
      isLoggedIn.value = false;
      clearFields();
      log('✅ Logout successful');
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      log('❌ Error during logout: $e');
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  // Snackbar helper methods
  void _showErrorSnackbar(String message) {
    CustomSnackbar.showSnackbar(
      title: 'Error',
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
    );
  }

  void _showSuccessSnackbar(String message) {
    CustomSnackbar.showSnackbar(
      title: 'Success',
      message: message,
      backgroundColor: AppColors.secondary,
      icon: Icons.check_circle_outline,
    );
  }

  @override
  void onClose() {
    credentialsController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
