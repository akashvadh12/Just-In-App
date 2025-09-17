import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/Data/services/notification_services.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/data/services/live_tracking_service_controller.dart';
import 'package:security_guard/data/services/session_service.dart';
import 'package:security_guard/data/services/sos_checkin_service.dart';
import 'package:security_guard/modules/issue/versionUpdateCheck/versionUpdateCheckScreen.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';

class HomeController extends GetxController {
  // User data from ProfileController
  final ProfileController profileController = Get.find<ProfileController>();
  final NotificationServices notify = NotificationServices();
  
  // SOS Service integration
  late SosCheckInService sosService;
  
  // Live Tracking Service integration
  late LiveTrackingService liveTrackingService;

  String get userName => profileController.userModel.value?.name ?? 'User';
  String get userPhotoUrl => profileController.userModel.value?.photoPath ?? '';
  String get userId => profileController.userModel.value?.userId ?? '';

  final notificationCount = 1.obs;
  final currentDate = DateTime.now().obs;

  @override
  void onReady() {
    super.onReady();
    
    // called after widget is built and mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionChecker.checkForUpdate(Get.context!);
      
      // Initialize services for guards (not admins)
      _initializeLiveTracking();
    });
  }

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    
    // Initialize SOS service
    if (!Get.isRegistered<SosCheckInService>()) {
      Get.put(SosCheckInService());
    }
    sosService = Get.find<SosCheckInService>();
    
    // Initialize Live Tracking service
    if (!Get.isRegistered<LiveTrackingService>()) {
      Get.put(LiveTrackingService());
    }
    liveTrackingService = Get.find<LiveTrackingService>();
  }

  @override
  void onClose() {
    sosService.stopService();
    liveTrackingService.stopTracking();
    super.onClose();
  }

  // Attendance data
  final hoursToday = '6h 15m'.obs;

  // Patrol data
  final completedPatrols = 4.obs;
  final totalPatrols = 6.obs;

  // Issues data
  final activeIssues = 2.obs;

  // Recent activities
  final recentActivities = [
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
  final clockInTime = 'Not clocked in'.obs;
  final clockOutTime = ''.obs;
  final todayPatrolStatus = ''.obs;
  final issuesNew = 0.obs;
  final issuesPending = 0.obs;
  final issuesResolved = 0.obs;
  final dashboardLoading = false.obs;

  // Service status observables
  final RxBool sosServiceActive = false.obs;
  final RxBool liveTrackingActive = false.obs;

  // Local storage service
  final LocalStorageService _storage = LocalStorageService.instance;

  // Formatting logic for the date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = currentDate.value.day;
    final month = months[currentDate.value.month - 1];
    return 'Monday, $month $day';
  }
  
// Initialize Live Tracking service
void _initializeLiveTracking() {
  // Set up reactive listeners
  _setupTrackingListeners();
  
  // Start tracking if conditions are met
  // _updateTrackingState();
}

// Setup reactive listeners
void _setupTrackingListeners() {
  // Listen to attendance changes
  ever(attendanceStatus, (_) => _updateTrackingState());
  
  // Listen to user model changes  
  ever(profileController.userModel, (_) => _updateTrackingState());
}

// Single method to handle all tracking logic
void _updateTrackingState() {
  final userModel = profileController.userModel.value;
  final shouldTrack = _shouldStartTracking(userModel);
  final isCurrentlyTracking = liveTrackingService.isTrackingActive.value;
  
  if (shouldTrack && !isCurrentlyTracking) {
    _startTracking();
  } else if (!shouldTrack && isCurrentlyTracking) {
    _stopTracking();
  }
}

// Check if tracking should be active
bool _shouldStartTracking(UserModel? userModel) {
  if (userModel == null) return false;
  
  final isAdmin = userModel.isAdmin == true;
  final isClockedIn = attendanceStatus.value == 'In' || userModel.clockStatus == true;
  final trackingEnabled = userModel.liveTrackingEnabled == true;
  
  return !isAdmin && isClockedIn && trackingEnabled;
}

// Start tracking with notification
void _startTracking() {
  liveTrackingService.startTracking().then((success) {
    liveTrackingActive.value = success;
    _showNotification(
      success ? 'GPS tracking started' : 'Failed to start GPS tracking',
      success ? Colors.green : Colors.red
    );
  });
}

// Stop tracking with notification
void _stopTracking() {
  liveTrackingService.stopTracking();
  liveTrackingActive.value = false;
  // _showNotification('GPS tracking stopped', Colors.orange);
}

// Simplified notification method
void _showNotification(String message, Color color) {
  if (Get.isSnackbarOpen) return;
  Get.snackbar(
    'Live Tracking',
    message,
    backgroundColor: color,
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 2),
    icon: Icon(
      color == Colors.green ? Icons.gps_fixed : Icons.gps_off,
      color: Colors.white,
    ),
  );
}


  Future<void> fetchDashboardData() async {
    final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return;
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
        'https://justin.solarvision-cairo.com/api/Dashboard/dashboard?userId=$userId',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        attendanceStatus.value = data['attendanceStatus']?.toString() ?? '';
        todayPatrolStatus.value = data['todayPatrolStatus']?.toString() ?? '';
        issuesNew.value = data['issuesCount']?['new'] ?? 0;
        issuesPending.value = data['issuesCount']?['pending'] ?? 0;
        issuesResolved.value = data['issuesCount']?['resolved'] ?? 0;
        clockInTime.value = data['clockIn']?.toString() ?? 'Not clocked in';
        clockOutTime.value = data['clockOut']?.toString() ?? '';

        print('Dashboard data fetched successfully: $data');
        
        // Initialize services after fetching attendance status
        _initializeLiveTracking();
        
        // Update user info/photo if present in dashboard response
        if (data['userID'] != null) {
          final session = Get.find<SessionService>();
          session.setSession(
            company: data['companyId'].toString(),
            site: data['siteId'].toString(),
          );
          
          // Update user model with new data
          profileController.userModel.value = UserModel.fromJson(data);
          profileController.fetchUserProfile(userId);
        }
      } else if (response.statusCode == 404) {
        Get.snackbar(
          "Not Found",
          "Dashboard data not found for user ID: $userId",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      } else if (response.statusCode == 500) {
        Get.snackbar(
          "Server Error",
          "Internal server error. Please try again later.",
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Oops!",
          "Dashboard not loading. Check your internet and try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error fetching dashboard data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('Error fetching dashboard data:🔴🔴🔴🐞🐞 $e');
    } finally {
      dashboardLoading.value = false;
    }
  }


  // Force refresh user model and reinitialize services
  void refreshUserModelAndServices() {
    final userId = profileController.userModel.value?.userId;
    if (userId != null && userId.isNotEmpty) {
      profileController.fetchUserProfile(userId).then((_) {
        _initializeLiveTracking();
      });
    }
  }

  // Stop all services (useful when logging out or switching users)
  void stopAllServices() {
    if (sosService.isServiceActive.value) {
      sosService.stopService();
      sosServiceActive.value = false;
    }
    
    if (liveTrackingService.isTrackingActive.value) {
      liveTrackingService.stopTracking();
      liveTrackingActive.value = false;
    }
  }

  // Start all services (useful when logging in or switching to guard role)
  void startAllServices() {
    _initializeLiveTracking();
  }
}