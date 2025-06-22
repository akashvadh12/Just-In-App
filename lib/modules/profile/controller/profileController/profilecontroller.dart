import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/data/services/api_post_service.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';

class ProfileController extends GetxController {
  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  // Only device token is stored in SharedPreferences
  final LocalStorageService _storage = LocalStorageService.instance;
  final ApiPostServices _apiPostService = ApiPostServices();
  final ApiGetServices _apiGetService = ApiGetServices();

  @override
  void onInit() {
    super.onInit();
    // You may want to load userId from an AuthController or similar
    // For demo, you can set userModel.value = ...
  }

  Future<void> fetchUserProfile(String userId) async {
    isLoading.value = true;
    try {
      final response = await _apiGetService.getProfileAPI(userId);
      if (response != null &&
          response['status'] == true &&
          response['user'] != null) {
        userModel.value = UserModel.fromJson(response['user']);
      } else {
        _showErrorSnackbar(response?['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to fetch profile data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    if (name.trim().isEmpty) {
      _showErrorSnackbar('Name cannot be empty');
      return;
    }
    isLoading.value = true;
    try {
      final response = await _apiPostService.updateProfileAPI(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
      );
      if (response != null) {
        userModel.value = userModel.value?.copyWith(
          name: name,
          email: email,
          phone: phone,
        );
        _showSuccessSnackbar('Profile updated successfully');
      } else {
        _showErrorSnackbar(response?['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      _showErrorSnackbar('Password fields cannot be empty');
      return;
    }
    if (newPassword.length < 6) {
      _showErrorSnackbar('New password must be at least 6 characters');
      return;
    }
    isLoading.value = true;
    try {
      final response = await _apiPostService.updatePasswordAPI(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      // Fixed: Use .contains() instead of .includes(), and fix the logic
      if (response!["message"].toString().contains(
        "Old password is incorrect.",
      )) {
        // This should show ERROR message, not success
        _showErrorSnackbar('Old password is incorrect.');
      } else {
        // If no error message, then it's successful
        _showSuccessSnackbar('Password updated successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update password');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    isLoading.value = true;
    try {
      final response = await _apiPostService.uploadProfileImageAPI(
        userId: userId,
        imageFile: imageFile,
      );
      if (response != null &&
          response['status'] == true &&
          response['profileImage'] != null) {
        userModel.value = userModel.value?.copyWith(
          photoPath: response['profileImage'],
        );
        _showSuccessSnackbar('Profile picture updated');
      } else {
        _showErrorSnackbar(
          response?['message'] ?? 'Failed to update profile picture',
        );
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update profile picture');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    userModel.value = null;
    await _storage.removeDeviceToken();
    Get.offAllNamed('/login');
  }

  // Snackbar helpers
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
