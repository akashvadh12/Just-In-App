import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/attandance/AttendanceScreen/capture_image.dart';
import 'package:security_guard/modules/home/controllers/home_controller.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';


class GuardAttendanceController extends GetxController {
  var capturedImage = Rx<File?>(null);
  var currentPosition = Rx<Position?>(null);
  var isLocationVerified = false.obs;
  var isClockedIn = false.obs;
  var lastAction = "No recent activity".obs;
  var clockInTime;
  var clockOutTime;
  var isLoadingLocation = false.obs;
  var isProcessingAttendance = false.obs;
  final ProfileController profileController = Get.find<ProfileController>();
  final HomeController dashboardController = Get.put(HomeController());
  final ApiGetServices _apiService = Get.find<ApiGetServices>();

  var stepIndex = 0.obs;
  void nextStep() => stepIndex.value++;
  void reset() => stepIndex.value = 0;

  @override
  void onInit() {
    super.onInit();
    // Initialize from dashboard state
    refreshUserState();
    print('GuardAttendanceController initialized');
  }

  // UPDATED: Refresh from Dashboard API instead of Profile API
  Future<void> refreshUserState() async {
    try {
      print('🔄 Refreshing state from Dashboard API...');
      
      // Fetch fresh data from dashboard
      await dashboardController.fetchDashboardData();
      
      // Update local state based on dashboard response
      final attendanceStatus = dashboardController.attendanceStatus.value;
      final userClockStatus = profileController.userModel.value?.clockStatus;
      
      // Clock status logic: true = clocked IN, false = clocked OUT
      isClockedIn.value = (attendanceStatus == 'In' || userClockStatus == true);

      
      print('✅ State refreshed - AttendanceStatus: $attendanceStatus, ClockStatus: $userClockStatus, isClockedIn: ${isClockedIn.value}');
    } catch (e) {
      print('❌ Error refreshing user state: $e');
    }
  }

  // UPDATED: Better error handling with Dashboard sync
  Future<bool> markAttendance(String type) async {
    final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      return false;
    }

    if (isProcessingAttendance.value) {
      print('Already processing attendance request');
      return false;
    }

    isProcessingAttendance.value = true;

    try {
      // Validate required data
      if (capturedImage.value == null || !await capturedImage.value!.exists()) {
        _showError(
          "Photo Required",
          "Please capture a verification photo first",
        );
        return false;
      }

      if (currentPosition.value == null || !isLocationVerified.value) {
        _showError("Location Required", "Please verify your location first");
        return false;
      }

      final userId = profileController.userModel.value?.userId;

      if (userId == null || userId.isEmpty) {
        _showError(
          "Authentication Error",
          "User ID not found. Please login again",
        );
        return false;
      }

      // Convert image to base64
      print('Converting image to base64...');
      final imageBase64 = await convertImageToBase64(capturedImage.value!);
      if (imageBase64 == null || imageBase64.isEmpty) {
        _showError("Image Error", "Failed to process verification photo");
        return false;
      }

      // Make API call
      final response = await _apiService.markAttendanceRaw(
        userId: userId,
        type: type,
        latitude: currentPosition.value!.latitude.toString(),
        longitude: currentPosition.value!.longitude.toString(),
        selfieBase64: imageBase64,
        selfieFile: capturedImage.value!,
        entryTimestamp: type == 'in' ? DateTime.now().toIso8601String() : null,
        exitTimestamp: type == 'out' ? DateTime.now().toIso8601String() : null,
      );

      print('=== API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Attendance marked successfully');
        return true;
      } else {
        // Handle error and sync with dashboard
        await _handleApiError(response, type);
        return false;
      }
    } catch (e) {
      print('❌ Exception in markAttendance: $e');
      _showError(
        "Network Error",
        "Failed to connect to server: ${e.toString()}",
      );
      return false;
    }
  }

  // UPDATED: Handle API errors with specific backend message detection
  Future<void> _handleApiError(http.Response response, String attemptedType) async {
    String errorMessage = "Attendance failed (Status: ${response.statusCode})";

    if (response.body.isNotEmpty) {
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map<String, dynamic>) {
          errorMessage =
              errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              errorData['Message']?.toString() ??
              errorData['Error']?.toString() ??
              errorMessage;
          
          // ✅ Detect specific backend error: "No entry record found"
          if (errorMessage.contains("No entry record found")) {
            print('🔍 Backend says: No open attendance record - User already clocked out');
            
            // Sync with dashboard to get correct state
            await refreshUserState();
            
            _showError(
              "Already Clocked Out",
              "You are already clocked out. State has been synchronized.",
            );
            return;
          }
          
          // ✅ Handle other potential state mismatch errors
          if (errorMessage.contains("already clocked in") || 
              errorMessage.contains("duplicate entry")) {
            print('🔍 Backend says: User already clocked in');
            await refreshUserState();
            
            _showError(
              "Already Clocked In",
              "You are already clocked in. State has been synchronized.",
            );
            return;
          }
        } else {
          errorMessage = response.body;
        }
      } catch (e) {
        print('Error parsing API response: $e');
        errorMessage = "Server error: ${response.body}";
      }
    }

    // For any error, refresh dashboard state
    print('🔄 Refreshing dashboard state after error...');
    await refreshUserState();
    
    print('❌ API Error: $errorMessage');
    _showError("Attendance Failed", errorMessage);
  }

  // UPDATED: Clock In with Dashboard state check
  Future<void> clockIn() async {
    if (isProcessingAttendance.value) return;

    try {
      isProcessingAttendance.value = true;

      // ✅ Step 1: Refresh from Dashboard API
      print('🔍 Checking current state from Dashboard before clock in...');
      await refreshUserState();

      // ✅ Step 2: Verify we can clock in
      if (isClockedIn.value == true || 
          profileController.userModel.value?.clockStatus == true ||
          dashboardController.attendanceStatus.value == 'In') {
        _showError(
          "Already Clocked In",
          "You are already clocked in. Please clock out first.",
        );
        isProcessingAttendance.value = false;
        return;
      }
      isProcessingAttendance.value = false;

      // ✅ Step 3: Proceed with clock in
      print('📍 Attempting to clock in...');
      final success = await markAttendance('in');

      if (success) {
        // Update all related states
        isClockedIn.value = true;
        profileController.userModel.value?.clockStatus = true;
        dashboardController.attendanceStatus.value = 'In';
        
        // Refresh dashboard to get updated data
        await dashboardController.fetchDashboardData();
        
        clockInTime = DateTime.now();
        lastAction.value = "Clocked-in at ${formatTime(clockInTime!)}";

        _showSuccess("Clock In Successful", "Welcome! Your shift has started");
        reset();
        resetAttendanceData();
        
        print('✅ Clock in completed successfully');
      }
    } catch (e) {
      print('❌ Error in clockIn: $e');
      _showError("Error", "Failed to clock in: ${e.toString()}");
      await refreshUserState();
    } finally {
      isProcessingAttendance.value = false;
    }
  }

  // UPDATED: Clock Out with Dashboard state check
  Future<void> clockOut() async {
    if (isProcessingAttendance.value) return;

    try {
      isProcessingAttendance.value = true;

      // ✅ Step 1: Refresh from Dashboard API
      print('🔍 Checking current state from Dashboard before clock out...');
      await refreshUserState();

      // ✅ Step 2: Verify we can clock out
      if (isClockedIn.value == false || 
          profileController.userModel.value?.clockStatus == false ||
          dashboardController.attendanceStatus.value != 'In') {
        _showError(
          "Already Clocked Out",
          "You are already clocked out. Please clock in first.",
        );
        isProcessingAttendance.value = false;
        return;
      }
      isProcessingAttendance.value = false;

      // ✅ Step 3: Proceed with clock out
      print('📍 Attempting to clock out...');
      final success = await markAttendance('out');

      if (success) {
        // Update all related states
        isClockedIn.value = false;
        profileController.userModel.value?.clockStatus = false;
        dashboardController.attendanceStatus.value = 'Out';
        
        // Refresh dashboard to get updated data
        await dashboardController.fetchDashboardData();
        
        clockOutTime = DateTime.now();
        lastAction.value = "Clocked-out at ${formatTime(clockOutTime!)}";

        _showSuccess(
          "Clock Out Successful",
          "Have a great day! Your shift has ended",
        );
        reset();
        resetAttendanceData();
        
        print('✅ Clock out completed successfully');
      }
    } catch (e) {
      print('❌ Error in clockOut: $e');
      _showError("Error", "Failed to clock out: ${e.toString()}");
      await refreshUserState();
    } finally {
      isProcessingAttendance.value = false;
    }
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
    );
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(10),
    );
  }

  // Keep all your existing helper methods
  
Future<void> capturePhoto() async {
  try {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final newStatus = await Permission.camera.request();
      if (!newStatus.isGranted) {
        Get.snackbar(
          'Permission Denied',
          'Camera permission is required to capture photo.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
    );

    if (image != null) {
      final File imageFile = File(image.path);
      final fileSize = await imageFile.length();

      if (fileSize > 3 * 1024 * 1024) {
        Get.snackbar(
          'Image Too Large',
          'Please use a smaller one',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      capturedImage.value = imageFile;
      nextStep();
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Could not capture photo',
      backgroundColor: Colors.red,
      snackPosition: SnackPosition.BOTTOM,
      colorText: Colors.white,
    );
    print(e);
  }
}

Future<void> getCurrentLocation() async {
  if (isLoadingLocation.value) return;
  final connectivityController = Get.find<ConnectivityController>();

  if (connectivityController.isOffline.value) {
    // connectivityController.showNoInternetSnackbar();
    return;
  }

  isLoadingLocation.value = true;

  try {
    // 1. Fetch office locations from API
    final officeResponse = await _apiService.getOfficeLocRaw();
    if (officeResponse.statusCode != 200) {
      Get.snackbar(
        "Office Location Error",
        "Failed to fetch office locations from server.",
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
      isLocationVerified.value = false;
      return;
    }

    final officeList = jsonDecode(officeResponse.body);
    if (officeList is! List || officeList.isEmpty) {
      Get.snackbar(
        "Office Location Error",
        "No office location data received.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
      isLocationVerified.value = false;
      return;
    }

    // 2. Check device location service and permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        "Location Service Disabled",
        "Please enable location services to continue",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.location_off, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        "Permission Denied Forever",
        "Please enable location permission from app settings",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      await Geolocator.openAppSettings();
      return;
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      Get.snackbar(
        "Permission Required",
        "Location permission is required for attendance",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 3. Get current location
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
    currentPosition.value = position;

    // 4. Compare against *all* office locations
    bool foundMatch = false;
    for (final office in officeList) {
      final officeLat = double.tryParse(office['latitude'].toString());
      final officeLng = double.tryParse(office['longitude'].toString());
      final officeRadius =
          double.tryParse(office['radius'].toString()) ?? 50.0;

      if (officeLat == null || officeLng == null) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLat,
        officeLng,
      );

      print(
        'Checking office at $officeLat,$officeLng → Distance: ${distance.toStringAsFixed(2)} m (radius $officeRadius m)',
      );

      if (distance <= officeRadius) {
        foundMatch = true;
        break;
      }
    }

    if (foundMatch) {
      isLocationVerified.value = true;
      Get.snackbar(
        "Location Verified",
        "GPS location verified successfully (within office range)",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.location_on, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
      nextStep();
     
    } else {
      isLocationVerified.value = false;
      Get.snackbar(
        "Out of Range",
        "You are not within the allowed office location range.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.location_off, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  } catch (e) {
    print('Location error: $e');
    isLocationVerified.value = false;
    currentPosition.value = null;

    Get.snackbar(
      "Location Error",
      "Unable to get your location. Please check settings.",
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.location_off, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  } finally {
    isLoadingLocation.value = false;
  }
}


  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String? storedUserId = prefs.getString('user_id');

      if (storedUserId == null || storedUserId.isEmpty) {
        final userDataString = prefs.getString('user_data');
        if (userDataString != null && userDataString.isNotEmpty) {
          try {
            final userData = jsonDecode(userDataString);
            if (userData is Map<String, dynamic> &&
                userData['userId'] != null) {
              storedUserId = userData['userId'].toString();
              if (storedUserId.isNotEmpty) {
                await prefs.setString('user_id', storedUserId);
              }
            }
          } catch (e) {
            print('Error parsing user data: $e');
          }
        }
      }

      print('Retrieved user ID: $storedUserId');
      return storedUserId?.isNotEmpty == true ? storedUserId : null;
    } catch (e) {
      print('Error retrieving user ID: $e');
      return null;
    }
  }

  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      return token?.isNotEmpty == true ? token : null;
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        print('Image file does not exist');
        return null;
      }

      final bytes = await imageFile.readAsBytes();

      if (bytes.isEmpty) {
        print('Image file is empty');
        return null;
      }

      final base64String = base64Encode(bytes);

      // Clean any potential whitespace or newlines
      final cleanBase64 = base64String.replaceAll(RegExp(r'\s'), '');

      // Basic validation
      if (cleanBase64.isEmpty) {
        print('Base64 string is empty after encoding');
        return null;
      }

      // Validate base64 format
      final base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      if (!base64Pattern.hasMatch(cleanBase64)) {
        print('Invalid base64 format detected');
        return null;
      }

      print('Base64 conversion successful - Length: ${cleanBase64.length}');
      return cleanBase64;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }


  bool get isReadyForAttendance {
    return capturedImage.value != null &&
        currentPosition.value != null &&
        isLocationVerified.value &&
        !isProcessingAttendance.value &&
        !isLoadingLocation.value;
  }

  String get attendanceStatusText {
    if (isProcessingAttendance.value) {
      return "Processing attendance...";
    }
    if (isLoadingLocation.value) {
      return "Getting location...";
    }
    if (capturedImage.value == null) {
      return "Please capture verification photo";
    }
    if (currentPosition.value == null || !isLocationVerified.value) {
      return "Please verify your location";
    }
    return "Ready for attendance";
  }

  String formatTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period";
  }

  String formatCoordinates(Position position) {
    String latDirection = position.latitude >= 0 ? 'N' : 'S';
    String longDirection = position.longitude >= 0 ? 'E' : 'W';
    return "Lat: ${position.latitude.abs().toStringAsFixed(4)}° $latDirection, Long: ${position.longitude.abs().toStringAsFixed(4)}° $longDirection";
  }

  void resetAttendanceData() {
    capturedImage.value = null;
    currentPosition.value = null;
    isLocationVerified.value = false;
    print('Attendance data reset');
  }

  @override
  void onClose() {
    print('GuardAttendanceController disposed');
    super.onClose();
  }
}
