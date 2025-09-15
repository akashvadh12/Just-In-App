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
  
    print('User ID from storage🔴🔴: ${profileController.userModel.value?.userId}');
  
    // called after widget is built and mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionChecker.checkForUpdate(Get.context!);
      
      // Initialize services for guards (not admins)
      _initializeServices();
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

  // Initialize both SOS and Live Tracking services
  void _initializeServices() {
    final userModel = profileController.userModel.value;
    final isAdmin = userModel?.isAdmin == true;
    final isClockedIn = attendanceStatus.value == 'In' || userModel?.clockStatus == true;
    
    print('🔵 Initializing services - IsAdmin: $isAdmin, IsClockedIn: $isClockedIn');
    print('🔵 Live tracking enabled: ${userModel?.liveTrackingEnabled}');
    print('🔵 Live tracking interval: ${userModel?.liveTrackingIntervalSeconds}s');
    
    if (!isAdmin && isClockedIn) {
      // Initialize SOS service
      _initializeSosService();
      
      // Initialize Live Tracking service
      _initializeLiveTracking();
    }
  }

  // Initialize SOS service based on user role
  void _initializeSosService() {
    final isAdmin = profileController.userModel.value?.isAdmin == true;
    
    if (!isAdmin && attendanceStatus.value == 'In') {
      // Only start SOS service for guards who are clocked in
      sosService.startService();
      sosServiceActive.value = true;
      
      // Listen to attendance status changes
      ever(attendanceStatus, (String status) {
        if (status == 'In' && !sosService.isServiceActive.value) {
          sosService.startService();
          sosServiceActive.value = true;
        } else if (status == 'Out' && sosService.isServiceActive.value) {
          sosService.stopService();
          sosServiceActive.value = false;
        }
      });
    }
  }

  // Initialize Live Tracking service
  void _initializeLiveTracking() {
    final userModel = profileController.userModel.value;
    final isAdmin = userModel?.isAdmin == true;
    final isClockedIn = attendanceStatus.value == 'In' || userModel?.clockStatus == true;
    final trackingEnabled = userModel?.liveTrackingEnabled == true;
    
    print('🟢 Live tracking initialization - Admin: $isAdmin, ClockedIn: $isClockedIn, Enabled: $trackingEnabled');
    
    if (!isAdmin && isClockedIn && trackingEnabled) {
      // Start live tracking for guards who are clocked in
      liveTrackingService.startTracking().then((success) {
        liveTrackingActive.value = success;
        if (success) {
          print('🟢 Live tracking started successfully');
          _showTrackingStatusNotification('Live GPS tracking started', Colors.green);
        } else {
          print('🔴 Failed to start live tracking');
          _showTrackingStatusNotification('Failed to start GPS tracking', Colors.red);
        }
      });
    }
    
    // Listen to attendance status changes for live tracking
    ever(attendanceStatus, (String status) {
      final currentUserModel = profileController.userModel.value;
      final trackingEnabled = currentUserModel?.liveTrackingEnabled == true;
      
      if (status == 'In' && trackingEnabled && !liveTrackingService.isTrackingActive.value) {
        // Start tracking when clocked in
        liveTrackingService.startTracking().then((success) {
          liveTrackingActive.value = success;
          if (success) {
            _showTrackingStatusNotification('GPS tracking started', Colors.green);
          }
        });
      } else if (status == 'Out' && liveTrackingService.isTrackingActive.value) {
        // Stop tracking when clocked out
        liveTrackingService.stopTracking();
        liveTrackingActive.value = false;
        _showTrackingStatusNotification('GPS tracking stopped', Colors.orange);
      }
    });
    
    // Listen to user model changes for tracking configuration updates
    ever(profileController.userModel, (UserModel? userModel) {
      if (userModel != null) {
        _handleTrackingConfigurationUpdate(userModel);
      }
    });
  }

  // Handle tracking configuration updates from user model
  void _handleTrackingConfigurationUpdate(UserModel userModel) {
    final isAdmin = userModel.isAdmin == true;
    final isClockedIn = attendanceStatus.value == 'In' || userModel.clockStatus == true;
    final trackingEnabled = userModel.liveTrackingEnabled == true;
    
    print('🔄 Tracking config update - Admin: $isAdmin, ClockedIn: $isClockedIn, Enabled: $trackingEnabled');
    
    if (!isAdmin && isClockedIn) {
      if (trackingEnabled && !liveTrackingService.isTrackingActive.value) {
        // Start tracking if enabled and not running
        liveTrackingService.startTracking().then((success) {
          liveTrackingActive.value = success;
        });
      } else if (!trackingEnabled && liveTrackingService.isTrackingActive.value) {
        // Stop tracking if disabled
        liveTrackingService.stopTracking();
        liveTrackingActive.value = false;
        _showTrackingStatusNotification('GPS tracking disabled', Colors.orange);
      }
    }
  }

  // Show tracking status notification
  void _showTrackingStatusNotification(String message, Color color) {
    Get.snackbar(
      'Live Tracking',
      message,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      icon: Icon(
        color == Colors.green ? Icons.gps_fixed : 
        color == Colors.red ? Icons.gps_off : Icons.gps_not_fixed,
        color: Colors.white,
      ),
    );
  }

  // Manual SOS trigger
  void triggerManualSos() {
    sosService.handleCheckInResponse(CheckInStatus.sos);
  }

  // Toggle SOS service (for testing or manual control)
  void toggleSosService() {
    if (sosService.isServiceActive.value) {
      sosService.stopService();
      sosServiceActive.value = false;
    } else {
      sosService.startService();
      sosServiceActive.value = true;
    }
  }

  // Manual live tracking controls
  void toggleLiveTracking() {
    if (liveTrackingService.isTrackingActive.value) {
      liveTrackingService.stopTracking();
      liveTrackingActive.value = false;
    } else {
      liveTrackingService.startTracking().then((success) {
        liveTrackingActive.value = success;
      });
    }
  }

  void manualLocationUpdate() {
    liveTrackingService.manualLocationUpdate();
  }

  // Get tracking statistics for debugging/monitoring
  Map<String, dynamic> getTrackingStats() {
    return liveTrackingService.getTrackingStats();
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
        _initializeServices();
        
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

  // Additional utility methods for service management
  
  // Get service status summary
  Map<String, dynamic> getServiceStatus() {
    return {
      'sosServiceActive': sosServiceActive.value,
      'liveTrackingActive': liveTrackingActive.value,
      'attendanceStatus': attendanceStatus.value,
      'isAdmin': profileController.userModel.value?.isAdmin ?? false,
      'trackingEnabled': profileController.userModel.value?.liveTrackingEnabled ?? false,
      'trackingStats': getTrackingStats(),
    };
  }

  // Force refresh user model and reinitialize services
  void refreshUserModelAndServices() {
    final userId = profileController.userModel.value?.userId;
    if (userId != null && userId.isNotEmpty) {
      profileController.fetchUserProfile(userId).then((_) {
        _initializeServices();
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
    _initializeServices();
  }
}