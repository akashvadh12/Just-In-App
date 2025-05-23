import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/routes/app_rout.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:security_guard/shared/widgets/bottomnavigation/bottomnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Import added

class AuthController extends GetxController {
  final credentialsController = TextEditingController(); // This can be userID or phone number
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isLoading = false.obs;
  final isSendingOTP = false.obs;
  final isLoginMode = true.obs;
  final isLoggedIn = false.obs;
  final loginWithPhone = false.obs; // <-- NEW toggle for login method

  void togglePasswordVisibility() {
    isPasswordHidden.toggle();
  }

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
    await Future.delayed(const Duration(seconds: 1));
    isLoggedIn.value = false;
  }

  void setLoggedIn(bool status) {
    isLoggedIn.value = status;
  }

  Future<void> login() async {
    final input = credentialsController.text.trim();
    final password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showErrorSnackbar('Please enter your ${loginWithPhone.value ? 'phone number' : 'user ID'} and password.');
      return;
    }

    isLoading.value = true;
    final url = Uri.parse(
      'https://qrapp.solarvision-cairo.com/api/User/UserAuthentication',
    );

    try {
      final body = loginWithPhone.value
          ? {
              "phoneNumber": input,
              "password": password,
            }
          : {
              "userName": input,
              "password": password,
            };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['status'] == true &&
          data['userInf']?.isNotEmpty == true) {
        final user = data['userInf'][0];
        final name = user['name'] ?? 'User';

        var deviceToken = user['deviceToken'];
        await _saveDeviceTokenToPrefs(deviceToken);

        setLoggedIn(true);
        _showSuccessSnackbar('Welcome, $name!');

        Get.offAll(() => BottomNavBarWidget());
      } else {
        _showErrorSnackbar('Invalid ${loginWithPhone.value ? 'phone number' : 'user ID'} or password');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveDeviceTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deviceToken', token);
  }

  Future<String?> getDeviceTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('deviceToken');
  }

  void sendOTP() async {
    if (credentialsController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter your phone number first');
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

  void logout() async {
    isLoggedIn.value = false;
    clearFields();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('deviceToken');

    // Optionally: Get.offAll(() => LoginScreen());
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
    );
  }

  @override
  void onClose() {
    credentialsController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
