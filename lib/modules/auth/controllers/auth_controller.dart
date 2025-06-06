import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'dart:convert';
import 'package:security_guard/routes/app_rout.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/bottomnavigation.dart';
import 'package:security_guard/data/services/api_post_service.dart';

class AuthController extends GetxController {
  final credentialsController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final isLoading = false.obs;
  final isSendingOTP = false.obs;
  final isLoginMode = true.obs;
  final isLoggedIn = false.obs;
  final loginWithPhone = false.obs;

  final _apiService = ApiPostServices();

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
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      isLoggedIn.value = false;
    }
  }

  void setLoggedIn(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', status);
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
    try {
      final responseData = await _apiService.login(
        input: input,
        password: password,
        loginWithPhone: loginWithPhone.value,
      );

      if (responseData['status'] == true &&
          (responseData['userInf']?.isNotEmpty ?? false)) {
        final userData = responseData['userInf'][0] as Map<String, dynamic>;
        final name = userData['name'] ?? 'User';
        final accessToken = userData['deviceToken'] ?? '';
        final userId =
            userData['userID']?.toString() ??
            ''; // 👈 Get userId here (make sure 'userID' is the correct key)

        final user = UserModel.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(user.toJson()));
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('auth_token', accessToken);
        await prefs.setString('user_id', userId); // 👈 Save userId here
        print('Raw userData: $userData');

        print("Auth Token saved: 😁😁👍 $accessToken");
        print("User ID saved: 😁😁👍 $userId");

        setLoggedIn(true);
        _showSuccessSnackbar('Welcome, $name!');

        Get.offAll(() => BottomNavBarWidget());
      } else {
        _showErrorSnackbar(
          'Invalid ${loginWithPhone.value ? 'phone number' : 'user ID'} or password.',
        );
      }
    } catch (e) {
      _showErrorSnackbar('Login failed. Please try again later.\nError: $e');
      print('Login error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print("Retrieved Auth Token: 😁😁👍 ${token ?? 'No token found'}");
      return token;
    } catch (e) {
      print("Error retrieving auth token: $e");
      return null;
    }
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      isLoggedIn.value = false;
      clearFields();

      Get.offAllNamed(Routes.LOGIN);
      print('Logout successful');
    } catch (e) {
      print('Error during logout: $e');
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
