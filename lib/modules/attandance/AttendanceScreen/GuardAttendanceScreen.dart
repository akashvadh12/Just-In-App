import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/modules/attandance/AttendanceHistoryScreen/AttendanceHistoryScreen.dart';
import 'package:security_guard/modules/attandance/attandance_controller/Attendance_controller.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';

class GuardAttendanceScreen extends StatelessWidget {
  final GuardAttendanceController controller = Get.put(
    GuardAttendanceController(),
  );
  final ProfileController profileController = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: controller.getCurrentLocation,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight * 0.9, // Ensure 90% height usage
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0), // Increased horizontal padding
                    child: Column(
                      children: [
                        _buildGreetingSection(),
                        const SizedBox(height: 16),
                        _buildCombinedVerificationSection(),
                        const SizedBox(height: 16),
                        _buildClockSection(),
                        const SizedBox(height: 16),
                        _buildQuickActions(),
                        const SizedBox(height: 16),
                        Spacer(), // Push content to use more vertical space
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      toolbarHeight: 70,
      title: Column(
        // mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Attendance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Digital Check-in System',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.history, color: Colors.white, size: 18),
          ),
          onPressed: () => Get.to(() => AttendanceHistoryScreen()),
        ),
        SizedBox(width: 12),
      ],
    );
  }

  Widget _buildGreetingSection() {
    final today = DateTime.now();
    final greeting = _getGreeting();
    final dateString =
        "${_weekday(today.weekday)}, ${today.day} ${_month(today.month)}, ${today.year}";

    return Container(
      padding: const EdgeInsets.all(20), // Increased padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${profileController.userModel.value?.name}!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16, // Increased font size
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateString,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 55, // Slightly increased
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: NetworkImage(
                  controller
                              .profileController
                              .userModel
                              .value
                              ?.photoPath
                              .isNotEmpty ==
                          true
                      ? controller.profileController.userModel.value!.photoPath
                      : 'https://cdn-icons-png.flaticon.com/512/1053/1053244.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedVerificationSection() {
    return Row(
      children: [
        Expanded(flex: 1, child: _buildLocationVerificationCard()),
        const SizedBox(width: 12),
        Expanded(flex: 1, child: _buildPhotoCard(Get.context!)),
      ],
    );
  }

  Widget _buildLocationVerificationCard() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16), // Increased padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Highlighted border and shadow
          border: Border.all(
            color: controller.isLocationVerified.value
                ? Colors.green.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: controller.isLocationVerified.value
                  ? Colors.green.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: controller.isLocationVerified.value
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.isLocationVerified.value
                        ? Icons.location_on
                        : Icons.location_off,
                    color: controller.isLocationVerified.value
                        ? Colors.green
                        : Colors.grey,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                if (controller.isLocationVerified.value)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              controller.isLocationVerified.value ? 'GPS Verified' : 'GPS Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: controller.isLocationVerified.value
                    ? Colors.green
                    : Colors.grey[700],
              ),
            ),
            Container(
              height: 28, // Increased height
              alignment: Alignment.centerLeft,
              child: controller.currentPosition.value != null
                  ? Text(
                      controller.formatCoordinates(
                        controller.currentPosition.value!,
                      ),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      'Location not available',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoadingLocation.value ||
                        controller.isLocationVerified.value
                    ? null
                    : controller.getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isLocationVerified.value
                      ? Colors.green
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: controller.isLoadingLocation.value
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Verifying...',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        // Updated text based on verification status
                        controller.isLocationVerified.value
                            ? 'Location Verified'
                            : 'Verify Location',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPhotoCard(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16), // Increased padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Highlighted border and shadow
          border: Border.all(
            color: controller.capturedImage.value != null
                ? Colors.green.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: controller.capturedImage.value != null
                  ? Colors.green.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Photo status indicator - green when captured
                Icon(
                  Icons.camera_alt,
                  color: controller.capturedImage.value != null
                      ? Colors.green // Green when photo is captured
                      : AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (controller.capturedImage.value != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () => controller.capturePhoto(context),
              child: Container(
                width: double.infinity,
                height: 110, // Increased height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: controller.capturedImage.value != null
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: controller.capturedImage.value != null
                      ? Stack(
                          children: [
                            Image.file(
                              controller.capturedImage.value!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey[50],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap to capture',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Required',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildClockSection() {
    return Obx(() {
      final now = DateTime.now();
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20), // Increased padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.formatTime(now),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 22, // Increased font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${now.day} ${_month(now.month)} ${now.year}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (profileController.userModel.value?.clockStatus == true
                            ? Colors.green
                            : Colors.grey)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (profileController.userModel.value?.clockStatus == true
                              ? Colors.green
                              : Colors.grey)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    profileController.userModel.value?.clockStatus == true
                        ? 'Clock-in'
                        : 'Clock-out',
                    style: TextStyle(
                      color: profileController.userModel.value?.clockStatus == true
                          ? Colors.green
                          : Colors.grey[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: profileController.userModel.value?.clockStatus == false
                  ? _buildCompactClockButton(
                      label: 'Clock-in', // Updated with hyphen
                      icon: Icons.login,
                      onPressed: controller.clockIn,
                      color: Colors.green,
                    )
                  : _buildCompactClockButton(
                      label: 'Clock-out', // Updated with hyphen
                      icon: Icons.logout,
                      onPressed: controller.clockOut,
                      color: Colors.red,
                    ),
            ),

            // if (controller.lastAction.value != "No recent activity") ...[
            //   const SizedBox(height: 16),
            //   Container(
            //     width: double.infinity,
            //     padding: const EdgeInsets.all(10),
            //     decoration: BoxDecoration(
            //       color: Colors.grey[50],
            //       borderRadius: BorderRadius.circular(10),
            //       border: Border.all(color: Colors.grey.withOpacity(0.2)),
            //     ),
            //     child: Center(
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Icon(Icons.history, color: Colors.grey[600], size: 16),
            //           const SizedBox(width: 8),
            //           Flexible(
            //             child: Text(
            //               controller.lastAction.value,
            //               style: TextStyle(
            //                 color: Colors.grey[700],
            //                 fontSize: 12,
            //                 fontWeight: FontWeight.w500,
            //               ),
            //               maxLines: 1,
            //               overflow: TextOverflow.ellipsis,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ],
          ],
        ),
      );
    });
  }

  Widget _buildCompactClockButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.to(() => AttendanceHistoryScreen()),
                child: _buildActionCard(
                  icon: Icons.history,
                  title: 'Attendance History',
                  subtitle: 'View records',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _weekday(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}