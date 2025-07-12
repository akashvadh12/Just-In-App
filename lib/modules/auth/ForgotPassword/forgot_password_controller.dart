import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Controller for the Forgot Password screen
class ForgotPasswordController extends GetxController {
  // Observable variables
  var phoneOrEmployeeId = ''.obs;
  var isPasswordSent = false.obs;
  var isLoading = false.obs;

  // Method to send reset code via API
  Future<void> sendResetCode() async {
    if (phoneOrEmployeeId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email or employee ID',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // // Validate email format (basic validation)
    // if (!phoneOrEmployeeId.value.contains('@') && 
    //     !phoneOrEmployeeId.value.contains('.')) {
    //   Get.snackbar(
    //     'Error',
    //     'Please enter a valid email address',
    //     snackPosition: SnackPosition.TOP,
    //     backgroundColor: Colors.red,
    //     colorText: Colors.white,
    //   );
    //   return;
    // }

    try {
      isLoading.value = true;
      
      // Encode email for URL
      String encodedEmail = Uri.encodeComponent(phoneOrEmployeeId.value);
      
      // API endpoint
      String apiUrl = 'https://justin.solarvision-cairo.com/api/Auth/forgot-password?email=$encodedEmail';
      
      // Make API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        // Success response
        String message = response.body;
        
        Get.snackbar(
          'Success',
          message.isNotEmpty ? message : 'Password has been sent to your registered employee ID or email address.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
        
        // Show success message and options
        isPasswordSent.value = true;
        
      } else if (response.statusCode == 404) {
        Get.snackbar(
          'Error',
          'Email or employee ID not found. Please check your email address.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else if (response.statusCode == 400) {
        Get.snackbar(
          'Error',
          'Invalid email or employee ID format.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        // Handle other error cases
        String errorMessage = 'Failed to send reset code. Please try again.';
        
        try {
          var errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // If response is not JSON, use default message
        }
        
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      
    } catch (e) {
      isLoading.value = false;
      
      Get.snackbar(
        'Error',
        'Network error. Please check your internet connection.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Method to resend password to email
  void resendPassword() {
    sendResetCode();
  }
}