import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/home/view/home_view.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/bottomnavigation.dart';
import 'package:security_guard/shared/widgets/custom_button.dart';
import '../../auth/controllers/auth_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            // App Logo
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            SizedBox(height: 16),
            // App Title
            Text(
              'Just IN',
              style: AppTextStyles.heading.copyWith(color: Colors.white),
            ),
            SizedBox(height: 6),
            // App Subtitle
            Text(
              'Secure Access for Security Professionals',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 24),
            // Login Form Container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Login/Signup Tabs
                      // Obx(
                      //   () => Row(
                      //     children: [
                      //       Expanded(
                      //         child: CustomButton(
                      //           text: 'Login',
                      //           backgroundColor:
                      //               authController.isLoginMode.value
                      //                   ? AppColors.primary
                      //                   : Colors.grey.shade100,
                      //           textColor:
                      //               authController.isLoginMode.value
                      //                   ? Colors.white
                      //                   : Colors.grey.shade800,
                      //           onPressed: () {
                      //             if (!authController.isLoginMode.value) {
                      //               authController.toggleMode();
                      //             }
                      //           },
                      //         ),
                      //       ),
                      //       Expanded(
                      //         child: CustomButton(
                      //           text: 'Signup',
                      //           backgroundColor:
                      //               !authController.isLoginMode.value
                      //                   ? AppColors.primary
                      //                   : Colors.grey.shade100,
                      //           textColor:
                      //               !authController.isLoginMode.value
                      //                   ? Colors.white
                      //                   : Colors.grey.shade800,
                      //           onPressed: () {
                      //             if (authController.isLoginMode.value) {
                      //               authController.toggleMode();
                      //             }
                      //           },
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      SizedBox(height: 24),

                      // Phone Number / Employee ID Field
                      Text(
                        'Phone Number / Employee ID',
                        style: AppTextStyles.subtitle.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: authController.credentialsController,

                        decoration: InputDecoration(
                          hintText: 'Enter your credentials',
                          hintStyle: AppTextStyles.hint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Password / OTP Field with Send OTP button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password / OTP',
                            style: AppTextStyles.subtitle.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Obx(
                            () => TextButton(
                              onPressed:
                                  authController.isSendingOTP.value
                                      ? null
                                      : () => authController.sendOTP(),
                              child:
                                  authController.isSendingOTP.value
                                      ? SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.greenColor,
                                        ),
                                      )
                                      : Text(
                                        'Send OTP',
                                        style: TextStyle(
                                          color: AppColors.greenColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Obx(
                        () => TextField(
                          controller: authController.passwordController,
                          obscureText: authController.isPasswordHidden.value,
                          decoration: InputDecoration(
                            hintText: 'Enter password or OTP',
                            hintStyle: AppTextStyles.hint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                authController.isPasswordHidden.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed:
                                  authController.togglePasswordVisibility,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Forgot Password Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              () => authController.navigateToForgotPassword(),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Login/Signup Button
                      Obx(
                        () => CustomButton(
                          text:
                              authController.isLoginMode.value
                                  ? 'Login'
                                  : 'Signup',
                          onPressed: () {
                            authController.login();
                            // authController.clearFields();
                          },
                          isLoading: authController.isLoading.value,
                        ),
                      ),
                      SizedBox(height: 24),

                      // Terms text
                      Text(
                        'By continuing, you agree to allow:',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Permission items
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Location access for attendance',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Camera access for verification',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),

                      // Bottom indicator
                      // Center(
                      //   child: Container(
                      //     width: 40,
                      //     height: 4,
                      //     decoration: BoxDecoration(
                      //       color: Colors.grey.shade300,
                      //       borderRadius: BorderRadius.circular(2),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
