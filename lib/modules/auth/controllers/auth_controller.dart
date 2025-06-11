import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/routes/app_rout.dart';

class AuthController extends GetxController {
  final credentialsController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isLoading = false.obs;
  final isSendingOTP = false.obs;
  final isLoginMode = true.obs;
  final isLoggedIn = false.obs;
  final loginWithPhone = false.obs;

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

  Future<void> checkLoginStatus() async {
    try {
      final storage = LocalStorageService.instance;
      isLoggedIn.value = storage.isLoggedIn();
    } catch (e) {
      print('Error checking login status: $e');
      isLoggedIn.value = false;
    }
  }

  void setLoggedIn(bool status) {
    isLoggedIn.value = status;
  }

  Future<void> login() async {
    final input = credentialsController.text.trim();
    final password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showErrorSnackbar(
        'Please enter your ${loginWithPhone.value ? 'phone number' : 'user ID'} and password.',
      );
      return;
    }

    isLoading.value = true;
    final url = Uri.parse(
      'https://official.solarvision-cairo.com/api/Auth/UserAuthentication',
    );

    try {
      final body =
          loginWithPhone.value
              ? {"phoneNumber": input, "password": password}
              : {"userName": input, "password": password};

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['status'] == true &&
          (data['userInf']?.isNotEmpty ?? false)) {
        final userData = data['userInf'][0];
        final name = userData['name'] ?? 'User';
        final deviceToken = userData['deviceToken'] ?? '';

        // Create user model from API response
        final user = UserModel.fromJson(userData);

        // Get storage service
        final storage = LocalStorageService.instance;

        // Save user data
        await storage.saveUserModel(user);

        // Save login status
        await storage.saveLoginStatus(true);

        // Save device token
        if (deviceToken != null && deviceToken.isNotEmpty) {
          await storage.saveString('deviceToken', deviceToken);
        }

        setLoggedIn(true);
        _showSuccessSnackbar('Welcome, $name!');

        Get.offAllNamed(Routes.BOTTOM_NAV);
      } else {
        _showErrorSnackbar(
          'Invalid ${loginWithPhone.value ? 'phone number' : 'user ID'} or password.',
        );
      }
    } catch (e) {
      _showErrorSnackbar('Login failed. Please try again later.\nError: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getAuthToken() async {
    final storage = LocalStorageService.instance;
    return storage.getToken();
  }

  Future<void> sendOTP() async {
    final phone = credentialsController.text.trim();
    if (phone.isEmpty) {
      _showErrorSnackbar('Please enter your phone number first.');
      return;
    }

    isSendingOTP.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isSendingOTP.value = false;

    _showSnackbar(
      title: 'Success',
      message: 'OTP sent successfully!',
      backgroundColor: AppColors.greenColor,
    );
  }

  void navigateToForgotPassword() {
    Get.toNamed(Routes.FORGOT_PASSWORD);
  }

  Future<void> logout() async {
    try {
      // Clear user data from storage
      final storage = LocalStorageService.instance;
      await storage.clearUserData();

      // Update UI state
      isLoggedIn.value = false;
      clearFields();

      // Navigate to login screen
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      print('Error during logout: $e');
      // Force navigation to login screen even if there's an error
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  void _showErrorSnackbar(String message) {
    _showSnackbar(
      title: 'Error',
      message: message,
      backgroundColor: AppColors.error,
    );
  }

  void _showSuccessSnackbar(String message) {
    _showSnackbar(
      title: 'Success',
      message: message,
      backgroundColor: AppColors.secondary,
    );
  }

  void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
    );
  }

  @override
  void onClose() {
    credentialsController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
