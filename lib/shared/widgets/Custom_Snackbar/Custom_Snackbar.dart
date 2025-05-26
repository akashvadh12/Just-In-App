import 'package:flutter/material.dart';
import 'package:get/get.dart';
 
class CustomSnackbar {
  static void showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      icon: const Icon(Icons.check_circle, color: Colors.white),
      shouldIconPulse: false,
      duration: const Duration(seconds: 2),
      barBlur: 10,
      overlayBlur: 2,
    );
  }
 
  static void showError(String title, String message, {IconData? icon}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      icon: Icon(icon ?? Icons.error, color: Colors.white),
      shouldIconPulse: false,
      duration: const Duration(seconds: 2),
      barBlur: 10,
      overlayBlur: 2,
    );
  }
 
 
  static void showWarning(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.orange.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      icon: const Icon(Icons.warning, color: Colors.white),
      shouldIconPulse: false,
      duration: const Duration(seconds: 2),
      barBlur: 10,
      overlayBlur: 2,
    );
  }
 
  static void showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      icon: const Icon(Icons.info, color: Colors.white),
      shouldIconPulse: false,
      duration: const Duration(seconds: 2),
      barBlur: 10,
      overlayBlur: 2,
    );
  }
}
 