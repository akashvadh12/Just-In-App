import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';

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
    fetchDashboardData();
  }

  // Attendance data
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

  // Dashboard data
  final attendanceStatus = ''.obs;
  final clockInTime = ''.obs;
  final todayPatrolStatus = ''.obs;
  final issuesNew = 0.obs;
  final issuesPending = 0.obs;
  final issuesResolved = 0.obs;
  final dashboardLoading = false.obs;

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

  final LocalStorageService _storage = LocalStorageService.instance;

  Future<void> fetchDashboardData() async {
        final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return ;
    }
    dashboardLoading.value = true;
    try {
      // Get userId from LocalStorageService
      String? userId = await _storage.getUserId();
      print('User ID from storage🔴🔴: $userId');
      if (userId == null || userId.isEmpty) {
        userId = profileController.userModel.value?.userId ?? '';
      }
      if (userId.isEmpty) {
        dashboardLoading.value = false;
        return;
      }
      final url = Uri.parse(
        'https://official.solarvision-cairo.com/dashboard?userId=$userId',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        attendanceStatus.value = data['attendanceStatus']?.toString() ?? '';
        todayPatrolStatus.value = data['todayPatrolStatus']?.toString() ?? '';
        issuesNew.value = data['issuesCount']?['new'] ?? 0;
        issuesPending.value = data['issuesCount']?['pending'] ?? 0;
        issuesResolved.value = data['issuesCount']?['resolved'] ?? 0;
        clockInTime.value = data['clockIn']?.toString() ?? '';

        print('Dashboard data fetched successfully: $data');
        // Update user info/photo if present in dashboard response
        if (data['userID'] != null) {
          profileController.userModel.value = UserModel.fromJson(data);
          profileController.fetchUserProfile(userId);
        }
      } else if (response.statusCode == 404) {
        Get.snackbar(
          "Not Found",
          "Dashboard data not found for user ID: $userId",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else if (response.statusCode == 500) {
        Get.snackbar(
          "Server Error",
          "Internal server error. Please try again later.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          "Oops!",
          "Dashboard not loading. Check your internet and try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching dashboard data');
      print('Error fetching dashboard data:🔴🔴🔴🐞🐞 $e');
    } finally {
      dashboardLoading.value = false;
    }
  }
}
