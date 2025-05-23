import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:security_guard/modules/auth/controllers/auth_controller.dart';
import 'package:security_guard/modules/auth/login/login_page.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';

class ProfileController extends GetxController {
  var selectedIndex = 4.obs;
  var userName = "John Anderson".obs;
  var userEmail = "john.anderson@security.com".obs;
  var userPhone = "+1 (555) 123-4567".obs;
  var userId = "GU-2024-0123".obs;
  var profileImage = "https://randomuser.me/api/portraits/men/32.jpg".obs;

  @override
  void onInit() {
    super.onInit();
    // Load user data from storage when controller initializes
    loadUserData();
  }

  void loadUserData() {
    try {
      final storage = LocalStorageService.instance;

      // Try to load from complete user model first
      final user = storage.getUserModel();
      if (user != null) {
        userName.value = user.name;
        userEmail.value = user.email ?? '';
        userId.value = user.userId;
        profileImage.value = user.photoPath;
        return;
      }

      // Fallback to individual fields for backward compatibility
      final savedName = storage.getUserName();
      final savedEmail = storage.getUserEmail();
      final savedPhone = storage.getUserPhone();
      final savedUserId = storage.getUserId();
      final savedProfileImage = storage.getProfileImage();

      if (savedName != null) userName.value = savedName;
      if (savedEmail != null) userEmail.value = savedEmail;
      if (savedPhone != null) userPhone.value = savedPhone;
      if (savedUserId != null) userId.value = savedUserId;
      if (savedProfileImage != null) profileImage.value = savedProfileImage;
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      final storage = LocalStorageService.instance;

      await storage.clearUserData();
      await storage.saveLoginStatus(false);

      // Update reactive variable if needed
      final authController = Get.find<AuthController>();
      authController.setLoggedIn(false);

      Get.snackbar(
        'Logged out',
        'You have been successfully logged out',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      Get.offAll(() => LoginPage());
    } catch (e) {
      print('Error during logout: $e');

      Get.snackbar(
        'Error',
        'Logout failed. Redirecting to login...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      Get.offAll(() => LoginPage());
    }
  }

  void updateProfile({String? name, String? email, String? phone}) async {
    try {
      // Update observable values
      if (name != null) userName.value = name;
      if (email != null) userEmail.value = email;
      if (phone != null) userPhone.value = phone;

      // Save to local storage
      final storage = LocalStorageService.instance;
      await storage.saveUserData(
        name: name ?? userName.value,
        email: email ?? userEmail.value,
        phone: phone ?? userPhone.value,
        userId: userId.value,
        profileImage: profileImage.value,
      );

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void updatePassword(String currentPassword, String newPassword) {
    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      Get.back(); // Close loading dialog

      // In a real app, you would validate the current password and update it
      // For now, we'll just show success
      Get.snackbar(
        'Success',
        'Password updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    });
  }

  Future<void> updateProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Update the profile image
        profileImage.value = image.path;

        // Save to storage
        final storage = LocalStorageService.instance;
        await storage.saveString('profile_image', image.path);

        Get.snackbar(
          'Success',
          'Profile picture updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile picture',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
