import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';

import 'package:security_guard/modules/home/view/home_view.dart';
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';
import 'package:security_guard/modules/issue/versionUpdateCheck/versionUpdateCheckScreen.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/modules/profile/liveChatScreen.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // _nameController.text = controller.userModel.value!.userName;
    // _emailController.text = controller.userModel.value!.email!;
    // _phoneController.text = controller.userModel.value!.phone!;
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
                subtitle: const Text('vedpal@cairovisions.com'),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL('mailto:vedpal@cairovisions.com');
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.blue),
                title: const Text('Call Support'),
                subtitle: const Text('+91 91086 28001'),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL('tel:+919108628001');
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
                controller.logout(); // 1. Call logout on your controller
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
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    if (controller.userModel.value == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    alignment: Alignment.center,
                    children: [
                      Obx(() {
                        final user = controller.userModel.value;
                        final imagePath = user?.photoPath ?? '';
                        Widget imageWidget;

                        if (imagePath.isEmpty) {
                          imageWidget = const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          );
                        } else if (imagePath.startsWith('http')) {
                          imageWidget = Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                          );
                        } else {
                          imageWidget = Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
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

                      // Camera button positioned at bottom-right of the profile image
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final user = controller.userModel.value;
                            if (user == null) return;

                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );

                            if (pickedFile != null) {
                              final imageFile = File(pickedFile.path);

                              // Show dialog with image preview and save button
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Header
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Preview Profile Picture',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                icon: const Icon(Icons.close),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // Image Preview
                                          Container(
                                            width: 200,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(98),
                                              child: Image.file(
                                                imageFile,
                                                width: 200,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Action Buttons
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Cancel Button
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),

                                              // Save Button
                                              ElevatedButton(
                                                onPressed: () async {
                                                  // // Show loading indicator
                                                  // Navigator.of(context).pop(); // Close dialog first

                                                  // // Show loading dialog
                                                  // showDialog(
                                                  //   context: context,
                                                  //   barrierDismissible: false,
                                                  //   builder: (BuildContext context) {
                                                  //     return const Dialog(
                                                  //       child: Padding(
                                                  //         padding: EdgeInsets.all(20),
                                                  //         child: Row(
                                                  //           mainAxisSize: MainAxisSize.min,
                                                  //           children: [
                                                  //             CircularProgressIndicator(),
                                                  //             SizedBox(width: 20),
                                                  //             Text('Updating profile picture...'),
                                                  //           ],
                                                  //         ),
                                                  //       ),
                                                  //     );
                                                  //   },
                                                  // );

                                                  try {
                                                    // Update profile picture
                                                    await controller
                                                        .updateProfilePicture(
                                                          userId: user.userId,
                                                          imageFile: imageFile,
                                                        );

                                                    // Close loading dialog
                                                    Navigator.of(context).pop();

                                                    // Refresh UI

                                                    // Show success message
                                                    // ScaffoldMessenger.of(context).showSnackBar(
                                                    //   const SnackBar(
                                                    //     content: Text('Profile picture updated successfully!'),
                                                    //     backgroundColor: Colors.green,
                                                    //   ),
                                                    // );
                                                  } catch (e) {
                                                    // Close loading dialog
                                                    Navigator.of(context).pop();

                                                    // Show error message
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Failed to update profile picture: $e',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text('Save'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.whiteColor,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // User Details
                  Obx(() {
                    final user = controller.userModel.value;
                    if (user == null) return const SizedBox();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Center(
                          child: Text(
                            user.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // User ID
                        if (user.userId != null && user.userId!.isNotEmpty) ...[
                          Center(
                            child: Text(
                              'Gaurd ID: ${user.gaurdId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Phone
                        if (user.phone != null && user.phone!.isNotEmpty) ...[
                          Center(
                            child: Text(
                              user.phone!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],

                        // Email
                        if (user.email != null && user.email!.isNotEmpty)
                          Center(
                            child: Text(
                              user.email!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
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
                        final user = controller.userModel.value;
                        _nameController.text = user?.name ?? '';
                        _emailController.text = user?.email ?? '';
                        _phoneController.text = user?.phone ?? '';
                      });
                    },
                  ),
                  // Edit Profile Section
                  // Add this at the top of your class (with other variables)

                  // Replace your edit profile section with this validated version:
                  if (_showEditProfileSection)
                    Container(
                      color: AppColors.whiteColor,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
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

                            // Full Name Field
                            const Text(
                              'Full Name',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
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
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters long';
                                }
                                if (value.trim().length > 50) {
                                  return 'Name must not exceed 50 characters';
                                }
                                // Check if name contains only letters and spaces
                                if (!RegExp(
                                  r'^[a-zA-Z\s]+$',
                                ).hasMatch(value.trim())) {
                                  return 'Name can only contain letters and spaces';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email Field (disabled but with validation for completeness)
                            const Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              enabled: false,
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
                                disabledBorder: OutlineInputBorder(
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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email address is required';
                                }
                                // Email regex pattern
                                if (!RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                ).hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone Number Field
                            const Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter your phone number',
                                counterText: '', // hides the character counter
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
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Phone number is required';
                                }
                                if (value.length != 10) {
                                  return 'Phone number must be exactly 10 digits';
                                }
                                // Check for valid Indian mobile number (starts with 6,7,8,9)
                                if (!RegExp(
                                  r'^[6-9][0-9]{9}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Update Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Validate form before proceeding
                                  if (_formKey.currentState!.validate()) {
                                    // Show loading indicator (optional)
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    );

                                    // Call your update method
                                    controller
                                        .updateProfile(
                                          userId:
                                              controller
                                                  .userModel
                                                  .value!
                                                  .userId,
                                          name: _nameController.text.trim(),
                                          email: _emailController.text.trim(),
                                          phone: _phoneController.text.trim(),
                                        )
                                        .then((_) {
                                          // Close loading dialog
                                          Navigator.of(context).pop();

                                          // Close the edit section
                                          setState(() {
                                            _showEditProfileSection = false;
                                          });
                                        })
                                        .catchError((error) {
                                          // Close loading dialog
                                          Navigator.of(context).pop();

                                          // Show error message
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error updating profile: $error',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        });
                                  }
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
                    ),
                  // const Divider(height: 1),

                  // Edit Profile Picture
                  // ListTile(
                  //   leading: Container(
                  //     padding: const EdgeInsets.all(6),
                  //     decoration: BoxDecoration(
                  //       color: Colors.blue,
                  //       borderRadius: BorderRadius.circular(4),
                  //     ),
                  //     child: const Icon(
                  //       Icons.camera_alt,
                  //       color: AppColors.whiteColor,
                  //       size: 20,
                  //     ),
                  //   ),
                  //   title: const Text('Edit Profile Picture'),
                  //   trailing: const Icon(Icons.chevron_right),
                  //   onTap: () async {
                  //     final user = controller.userModel.value;
                  //     if (user == null) return;

                  //     final picker = ImagePicker();
                  //     final pickedFile = await picker.pickImage(
                  //       source: ImageSource.gallery,
                  //       imageQuality: 80,
                  //     );

                  //     if (pickedFile != null) {
                  //       final imageFile = File(pickedFile.path);

                  //       // Show dialog with image preview and save button
                  //       showDialog(
                  //         context: context,
                  //         builder: (BuildContext context) {
                  //           return Dialog(
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(12),
                  //             ),
                  //             child: Container(
                  //               padding: const EdgeInsets.all(16),
                  //               child: Column(
                  //                 mainAxisSize: MainAxisSize.min,
                  //                 children: [
                  //                   // Header
                  //                   Row(
                  //                     mainAxisAlignment:
                  //                         MainAxisAlignment.spaceBetween,
                  //                     children: [
                  //                       const Text(
                  //                         'Preview Profile Picture',
                  //                         style: TextStyle(
                  //                           fontSize: 18,
                  //                           fontWeight: FontWeight.bold,
                  //                         ),
                  //                       ),
                  //                       IconButton(
                  //                         onPressed:
                  //                             () => Navigator.of(context).pop(),
                  //                         icon: const Icon(Icons.close),
                  //                       ),
                  //                     ],
                  //                   ),
                  //                   const SizedBox(height: 16),

                  //                   // Image Preview
                  //                   Container(
                  //                     width: 200,
                  //                     height: 200,
                  //                     decoration: BoxDecoration(
                  //                       borderRadius: BorderRadius.circular(
                  //                         100,
                  //                       ),
                  //                       border: Border.all(
                  //                         color: Colors.grey.shade300,
                  //                         width: 2,
                  //                       ),
                  //                     ),
                  //                     child: ClipRRect(
                  //                       borderRadius: BorderRadius.circular(98),
                  //                       child: Image.file(
                  //                         imageFile,
                  //                         width: 200,
                  //                         height: 200,
                  //                         fit: BoxFit.cover,
                  //                       ),
                  //                     ),
                  //                   ),
                  //                   const SizedBox(height: 24),

                  //                   // Action Buttons
                  //                   Row(
                  //                     mainAxisAlignment:
                  //                         MainAxisAlignment.spaceEvenly,
                  //                     children: [
                  //                       // Cancel Button
                  //                       TextButton(
                  //                         onPressed:
                  //                             () => Navigator.of(context).pop(),
                  //                         child: const Text(
                  //                           'Cancel',
                  //                           style: TextStyle(
                  //                             color: Colors.grey,
                  //                           ),
                  //                         ),
                  //                       ),

                  //                       // Save Button
                  //                       ElevatedButton(
                  //                         onPressed: () async {
                  //                           // // Show loading indicator
                  //                           // Navigator.of(context).pop(); // Close dialog first

                  //                           // // Show loading dialog
                  //                           // showDialog(
                  //                           //   context: context,
                  //                           //   barrierDismissible: false,
                  //                           //   builder: (BuildContext context) {
                  //                           //     return const Dialog(
                  //                           //       child: Padding(
                  //                           //         padding: EdgeInsets.all(20),
                  //                           //         child: Row(
                  //                           //           mainAxisSize: MainAxisSize.min,
                  //                           //           children: [
                  //                           //             CircularProgressIndicator(),
                  //                           //             SizedBox(width: 20),
                  //                           //             Text('Updating profile picture...'),
                  //                           //           ],
                  //                           //         ),
                  //                           //       ),
                  //                           //     );
                  //                           //   },
                  //                           // );

                  //                           try {
                  //                             // Update profile picture
                  //                             await controller
                  //                                 .updateProfilePicture(
                  //                                   userId: user.userId,
                  //                                   imageFile: imageFile,
                  //                                 );

                  //                             // Close loading dialog
                  //                             Navigator.of(context).pop();

                  //                             // Refresh UI

                  //                             // Show success message
                  //                             // ScaffoldMessenger.of(context).showSnackBar(
                  //                             //   const SnackBar(
                  //                             //     content: Text('Profile picture updated successfully!'),
                  //                             //     backgroundColor: Colors.green,
                  //                             //   ),
                  //                             // );
                  //                           } catch (e) {
                  //                             // Close loading dialog
                  //                             Navigator.of(context).pop();

                  //                             // Show error message
                  //                             ScaffoldMessenger.of(
                  //                               context,
                  //                             ).showSnackBar(
                  //                               SnackBar(
                  //                                 content: Text(
                  //                                   'Failed to update profile picture: $e',
                  //                                 ),
                  //                                 backgroundColor: Colors.red,
                  //                               ),
                  //                             );
                  //                           }
                  //                         },
                  //                         style: ElevatedButton.styleFrom(
                  //                           backgroundColor: Colors.blue,
                  //                           foregroundColor: Colors.white,
                  //                           padding: const EdgeInsets.symmetric(
                  //                             horizontal: 24,
                  //                             vertical: 12,
                  //                           ),
                  //                           shape: RoundedRectangleBorder(
                  //                             borderRadius:
                  //                                 BorderRadius.circular(8),
                  //                           ),
                  //                         ),
                  //                         child: const Text('Save'),
                  //                       ),
                  //                     ],
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //           );
                  //         },
                  //       );
                  //     }
                  //   },
                  // ),
                  const Divider(height: 1),

                  //   if(controller.userModel.value!.isAdmin == true)
                  // ListTile(
                  //   leading: Container(
                  //     padding: const EdgeInsets.all(6),
                  //     decoration: BoxDecoration(
                  //       color: Colors.blue,
                  //       borderRadius: BorderRadius.circular(4),
                  //     ),
                  //     child: const Icon(
                  //       Icons.lock,
                  //       color: AppColors.whiteColor,
                  //       size: 20,
                  //     ),
                  //   ),
                  //   title: const Text('Add New Location'),
                  //   trailing: const Icon(Icons.chevron_right),
                  //   onTap: () {},
                  // ),
                  // const Divider(height: 1),

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
                  Divider(height: 1),

                  // Password Change Section
                  if (_showPasswordSection)
                    Container(
                      color: AppColors.whiteColor,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add these boolean variables to your State class

                          // Updated widget code
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
                            obscureText: !_isCurrentPasswordVisible,
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isCurrentPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isCurrentPasswordVisible =
                                        !_isCurrentPasswordVisible;
                                  });
                                },
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
                            obscureText: !_isNewPasswordVisible,
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isNewPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isNewPasswordVisible =
                                        !_isNewPasswordVisible;
                                  });
                                },
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
                            obscureText: !_isConfirmPasswordVisible,
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
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
                                  userId: controller.userModel.value!.userId,
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

            // Logout Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Version 1.03.47',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  // GestureDetector(
                  //   onTap: () {
                  //     // Handle tap - navigate to version screen or check updates
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const VersionUpdateScreen(),
                  //       ),
                  //     );
                  //   },
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 4,
                  //     ),
                  //     decoration: BoxDecoration(
                  //       color: AppColors.primary.withOpacity(0.1),
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(
                  //         color: AppColors.primary.withOpacity(0.3),
                  //       ),
                  //     ),
                  //     child: Text(
                  //       'Check Updates',
                  //       style: TextStyle(
                  //         color: AppColors.primary,
                  //         fontSize: 10,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
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

For questions about these Terms, please contact vedpal@cairovisions.com.
''';
  }

  // Privacy Policy content
String _getPrivacyPolicy() {
  return '''
Effective Date: 20-07-2025

Last Updated: 20-07-2025

App Name: JustIn

Developer & Owner: Cairovision Private Limited

Contact Email: vedpal@cairovisions.com

1. Introduction  
This Privacy Policy explains how we collect, use, and protect information through our mobile application ("App"). The App is part of a SaaS (Software as a Service) platform developed and owned by Cairovision Private Limited, designed for use by companies to manage their workforce operations, particularly in security and field service industries.  
The app is not available for public use. Only authorized company administrators can onboard employees. Users (employees) cannot create their own accounts independently.

2. Platform Access Model  
Each subscribing company acts as an independent admin (tenant) on the platform.  
Admins can manage their own employee data, accounts, access, and logs.  
No public or self-sign-up is allowed. Users are created and managed by their respective company admin.  
The platform is multi-tenant: each company's data is isolated and secure.

3. Permissions and Usage  
📍 Location  
Permission: ACCESS_FINE_LOCATION  
Purpose: To track and log user location for duty verification, attendance, and shift monitoring.  

📷 Camera  
Permissions: CAMERA, FOREGROUND_SERVICE_CAMERA  
Purpose: Used for image capture in reports, identity validation, and QR scanning.  

🗂️ Media & Storage  
Permissions:  
- READ_EXTERNAL_STORAGE (Android ≤12)  
- WRITE_EXTERNAL_STORAGE (Android ≤9)  
- READ_MEDIA_IMAGES (Android 13+)  
Purpose: To read and upload job-related files and images.  

🌐 Internet  
Permission: INTERNET  
Purpose: Required for syncing, authentication, reporting, and cloud communication.  

💡 Hardware Access  
Permission: android.hardware.camera.flash  
Purpose: Enables flashlight for inspections or low-light conditions.

4. Data We Collect  
- Location logs during duty hours  
- Incident reports, including images if submitted  
- Patrol logs, check-ins, task activity, timestamps  
- Device metadata (e.g., device model, OS version – limited use)  
- Admin-generated assignments and roles  
We do not collect any personal data unrelated to official company use.

5. Data Retention & Deactivation  
Data collected via the app becomes part of the company’s internal job records and is not deleted on user request.  
If an employee wants to stop using the app, they may request account deactivation by contacting their company admin.  
Data is retained based on each company’s operational and legal policies.

6. Security  
- End-to-end encryption  
- Role-based access controls  
- Secured cloud infrastructure  
- Company-wise data segregation  
- Regular backups and audit logs

7. Data Sharing  
Data is only accessible by the employing company and platform admins (Cairovision Pvt Ltd) for system maintenance or compliance.  
We do not sell or share data with any third parties.  
Data may be disclosed to law enforcement or legal authorities when required by law.

8. Children’s Privacy  
This app is intended exclusively for workplace use. It is not directed toward, nor intended for, children under the age of 13.

9. Policy Changes  
We may update this Privacy Policy to reflect feature updates, legal compliance, or operational improvements. Material changes will be communicated through the app or via admin announcements.

10. Contact Information  
Developer/Owner: Cairovision Private Limited  
📧 Support Email: vedpal@cairovisions.com  
If you are an employee using this app, please contact your company administrator for any data or access-related queries.
''';
}

}
