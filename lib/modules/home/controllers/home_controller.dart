import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';

class HomeController extends GetxController {
  // User data from ProfileController
  final ProfileController profileController = Get.find<ProfileController>();

  String get userName => profileController.userModel.value?.name ?? 'User';
  String get userPhotoUrl => profileController.userModel.value?.photoPath ?? '';
  String get userId => profileController.userModel.value?.userId ?? '';

  final notificationCount = 1.obs;
  final currentDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    // No need to load user data from storage, ProfileController handles it
  }

  // Attendance data
  final isClockIn = true.obs;
  final clockInTime = '07:45 AM'.obs;
  final hoursToday = '6h 15m'.obs;

  // Patrol data
  final completedPatrols = 4.obs;
  final totalPatrols = 6.obs;

  // Issues data
  final activeIssues = 2.obs;

  // Recent activities
  final recentActivities =
      [
        {
          'type': 'patrol',
          'title': 'Completed patrol round 6',
          'time': '15m ago',
          'icon': Icons.directions_walk,
        },
        {
          'type': 'attendance',
          'title': 'Marked attendance',
          'time': '2h ago',
          'icon': Icons.fingerprint,
        },
        {
          'type': 'issue',
          'title': 'Resolved issue #45',
          'time': '4h ago',
          'icon': Icons.warning,
        },
      ].obs;

  // Navigation index
  final selectedIndex = 0.obs;

  // Formatting logic for the date
  String get formattedDate {
    final months = [
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
    final day = currentDate.value.day;
    final month = months[currentDate.value.month - 1];
    return 'Monday, $month $day';
  }

  // Actions
  void startPatrol() {
    Get.snackbar(
      'Patrol Started',
      'You have started a new patrol round',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    // Implementation for starting patrol
  }

  void markAttendance() {
    Get.snackbar(
      'Attendance Marked',
      'Your attendance has been recorded',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
    // Implementation for marking attendance
  }

  void raiseIssue() {
    // Navigate to issue reporting screen
    // Get.toNamed(Routes.REPORT_ISSUE);
    Get.snackbar(
      'Report Issue',
      'Navigating to issue reporting form',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void navigateTo(int index) {
    selectedIndex.value = index;
    // Implementation for navigation
  }
}
