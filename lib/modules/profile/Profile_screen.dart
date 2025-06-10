import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';

import 'package:security_guard/modules/home/view/home_view.dart';
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/modules/profile/liveChatScreen.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';

// Mock live chat screen
class LiveChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Get.put(LocalStorageService());
    return Scaffold(
      appBar: AppBar(title: const Text('Live Chat Support'), elevation: 0),
      body: Center(child: Text('Live Chat Screen Coming Soon')),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController controller = Get.put(ProfileController());
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _showPasswordSection = false;
  bool _showEditProfileSection = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = controller.userName.value;
    _emailController.text = controller.userEmail.value;
    _phoneController.text = controller.userPhone.value;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Method to open a URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await url_launcher.launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  // Show contact support dialog
  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Email Support'),
                subtitle: const Text('support@securityguard.com'),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL('mailto:support@securityguard.com');
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.blue),
                title: const Text('Call Support'),
                subtitle: const Text('+1 (800) 123-4567'),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL('tel:+18001234567');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.blue),
                title: const Text('Live Chat'),
                subtitle: const Text('Available 24/7'),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(
                    () => LiveChatScreen(),
                  ); // Replace with your chat screen
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Show logout confirmation dialog
void _showLogoutConfirmationDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel closes dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.logout();    // 1. Call logout on your controller
              Navigator.pop(context); // 2. Close the dialog
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    Get.put(LocalStorageService());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Info Section
            Container(
              width: double.infinity,
              color: AppColors.whiteColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Image
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Obx(() {
                        final imagePath = controller.profileImage.value;

                        Widget imageWidget;

                        if (imagePath.isEmpty) {
                          // No image selected, show placeholder icon
                          imageWidget = const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          );
                        } else if (imagePath.startsWith('http') ||
                            imagePath.startsWith('https')) {
                          // It's a URL, use Image.network
                          imageWidget = Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              );
                            },
                          );
                        } else {
                          // Assume it's a local file path, use Image.file
                          imageWidget = Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              );
                            },
                          );
                        }

                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.lightGrey,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: imageWidget,
                          ),
                        );
                      }),

                      // GestureDetector(
                      //   onTap: () async {
                      //     // Add image picker functionality
                      //     await controller.updateProfilePicture();
                      //   },
                      //   child: Container(
                      //     padding: const EdgeInsets.all(4),
                      //     decoration: const BoxDecoration(
                      //       color: Colors.blue,
                      //       shape: BoxShape.circle,
                      //     ),
                      //     child: const Icon(
                      //       Icons.camera_alt,
                      //       color: AppColors.whiteColor,
                      //       size: 18,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User Name
                  Obx(
                    () => Text(
                      controller.userName.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // User ID
                  Obx(
                    () => Text(
                      'ID: ${controller.userId.value}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // User Contact Info
                  Obx(
                    () => Text(
                      controller.userPhone.value,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      controller.userEmail.value,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Profile Actions Section
            Container(
              color: AppColors.whiteColor,
              child: Column(
                children: [
                  // Edit Profile
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: AppColors.whiteColor,
                        size: 20,
                      ),
                    ),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() {
                        _showEditProfileSection = !_showEditProfileSection;
                        _showPasswordSection = false;
                        _nameController.text = controller.userName.value;
                        _emailController.text = controller.userEmail.value;
                        _phoneController.text = controller.userPhone.value;
                      });
                    },
                  ),
                  // Edit Profile Section
                  if (_showEditProfileSection)
                    Container(
                      color: AppColors.whiteColor,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Name
                          const Text(
                            'Full Name',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Email
                          const Text(
                            'Email Address',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Phone
                          const Text(
                            'Phone Number',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter your phone number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Update Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.updateProfile(
                                  name: _nameController.text,
                                  email: _emailController.text,
                                  phone: _phoneController.text,
                                );
                                setState(() {
                                  _showEditProfileSection = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Update Profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  // Edit Profile Picture
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppColors.whiteColor,
                        size: 20,
                      ),
                    ),
                    title: const Text('Edit Profile Picture'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      // Add image picker functionality
                      await controller.updateProfilePicture();
                    },
                  ),
                  const Divider(height: 1),
                  // Change Password
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: AppColors.whiteColor,
                        size: 20,
                      ),
                    ),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() {
                        _showPasswordSection = !_showPasswordSection;
                        _showEditProfileSection = false;
                      });
                    },
                  ),

                  // Password Change Section
                  if (_showPasswordSection)
                    Container(
                      color: AppColors.whiteColor,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Current Password
                          const Text(
                            'Current Password',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Enter current password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // New Password
                          const Text(
                            'New Password',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Enter new password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Confirm Password
                          const Text(
                            'Confirm Password',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Confirm new password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Password Requirements
                          const Text(
                            'Password must be at least 8 characters long and include numbers and special characters',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          // Update Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Validate passwords
                                if (_newPasswordController.text.isEmpty ||
                                    _currentPasswordController.text.isEmpty ||
                                    _confirmPasswordController.text.isEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    'All password fields are required',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                if (_newPasswordController.text !=
                                    _confirmPasswordController.text) {
                                  Get.snackbar(
                                    'Error',
                                    'New password and confirm password do not match',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                // Password validation - at least 8 chars with numbers and special chars
                                String password = _newPasswordController.text;
                                RegExp passwordRegex = RegExp(
                                  r'^(?=.*?[0-9])(?=.*?[!@#$%^&*(),.?":{}|<>]).{8,}$',
                                );
                                if (!passwordRegex.hasMatch(password)) {
                                  Get.snackbar(
                                    'Error',
                                    'Password must be at least 8 characters and include numbers and special characters',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                controller.updatePassword(
                                  oldPassword: _currentPasswordController.text,
                                  newPassword: _newPasswordController.text,
                                );

                                // Clear fields and hide section
                                _currentPasswordController.clear();
                                _newPasswordController.clear();
                                _confirmPasswordController.clear();
                                setState(() {
                                  _showPasswordSection = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Update Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Divider(height: 1),
                  // Support and Legal Section
                  Container(
                    color: AppColors.whiteColor,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.headset_mic,
                              color: AppColors.whiteColor,
                              size: 20,
                            ),
                          ),
                          title: const Text('Contact Support'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showContactSupportDialog();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.description,
                              color: AppColors.whiteColor,
                              size: 20,
                            ),
                          ),
                          title: const Text('Terms & Conditions'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navigate to Terms & Conditions screen
                            Get.to(
                              () => LegalDocumentScreen(
                                title: 'Terms & Conditions',
                                content: _getTermsAndConditions(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.shield,
                              color: AppColors.whiteColor,
                              size: 20,
                            ),
                          ),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navigate to Privacy Policy screen
                            Get.to(
                              () => LegalDocumentScreen(
                                title: 'Privacy Policy',
                                content: _getPrivacyPolicy(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // App Version
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),

            // Logout Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  _showLogoutConfirmationDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Terms and Conditions content
  String _getTermsAndConditions() {
    return '''
# Terms and Conditions for Security Guard App

Last Updated: May 21, 2025

## 1. Acceptance of Terms

By accessing or using the Security Guard App ("the App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, please do not use the App.

## 2. Changes to Terms

We reserve the right to modify these Terms at any time. We will provide notice of any material changes through the App or by other means. Your continued use of the App after such modifications constitutes your acceptance of the modified Terms.

## 3. User Accounts

- You are responsible for maintaining the confidentiality of your account information.
- You are responsible for all activities that occur under your account.
- You must immediately notify us of any unauthorized use of your account.

## 4. User Conduct

You agree not to:
- Use the App for any illegal purpose
- Submit false or misleading information
- Interfere with the proper working of the App
- Attempt to gain unauthorized access to the App or its systems

## 5. Intellectual Property Rights

The App and its contents are owned by us and are protected by copyright, trademark, and other laws. You may not use our intellectual property without our prior written consent.

## 6. Limitation of Liability

To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages.

## 7. Termination

We may terminate or suspend your access to the App immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users of the App, us, or third parties, or for any other reason.

## 8. Governing Law

These Terms shall be governed by and construed in accordance with the laws of the state/country where our company is registered, without regard to its conflict of law provisions.

## 9. Contact Information

For questions about these Terms, please contact support@securityguard.com.
''';
  }

  // Privacy Policy content
  String _getPrivacyPolicy() {
    return '''
# Privacy Policy for Security Guard App

Last Updated: May 21, 2025

## 1. Introduction

This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our Security Guard App ("the App"). Please read this Privacy Policy carefully. By using the App, you consent to the data practices described in this policy.

## 2. Information Collection

We may collect several types of information from and about users of our App, including:

- Personal Information: Name, email address, phone number, and other identifiers.
- Employment Information: Job title, work location, shift details, and performance data.
- Location Data: Real-time geographic location of your device when using patrol features.
- Device Information: Device type, operating system, unique device identifiers.
- Usage Data: How you interact with our App.

## 3. How We Use Your Information

We use the information we collect to:

- Provide and maintain our services
- Notify you about changes to our App
- Allow you to participate in interactive features
- Monitor and analyze usage patterns and trends
- Improve our App and user experience
- Send service-related notifications

## 4. Data Security

We implement appropriate technical and organizational measures to protect the security of your personal information. However, please be aware that no method of transmission over the internet or method of electronic storage is 100% secure.

## 5. Data Sharing and Disclosure

We may share your information with:

- Service providers who perform services on our behalf
- Law enforcement or other government officials, if required by law
- Your employer, as necessary for employment-related purposes
- In connection with a business transfer or acquisition

## 6. Your Rights

Depending on your location, you may have certain rights regarding your personal information, including:

- Access to your personal information
- Correction of inaccurate information
- Deletion of your information
- Objection to processing
- Data portability

## 7. Changes to This Privacy Policy

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.

## 8. Contact Us

If you have any questions about this Privacy Policy, please contact us at:
- Email: privacy@securityguard.com
- Phone: +1 (800) 123-4567
''';
  }
}
