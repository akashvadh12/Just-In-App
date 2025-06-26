import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/home/controllers/home_controller.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

  // API endpoint
  static const String attendanceApiUrl =
      'https://official.solarvision-cairo.com/api/AttendanceRecord/attendance/mark';

  @override
  void onInit() {
    super.onInit();
    isClockedIn.value = profileController.userModel.value?.clockStatus ?? false;
    print('GuardAttendanceController initialized');
    print(
      'Clocked In: ${isClockedIn.value} - User In: ${profileController.userModel.value?.clockStatus}',
    );
  }

  Future<void> capturePhoto() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        preferredCameraDevice: CameraDevice.front,
        // maxWidth: 1024,
        // maxHeight: 768,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Check if file exists and is valid
        if (!await file.exists()) {
          throw Exception('Captured image file not found');
        }

        final fileSize = await file.length();
        print(
          'Captured image size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
        );

        if (fileSize > 3 * 1024 * 1024) {
          // 3MB limit
          Get.snackbar(
            "Image Too Large",
            "Please capture a smaller image or reduce quality",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            icon: const Icon(Icons.warning, color: Colors.white),
            duration: const Duration(seconds: 3),
          );
          return;
        }

        capturedImage.value = file;

        Get.snackbar(
          "Photo Captured",
          "Verification photo taken successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error capturing photo: $e');
      Get.snackbar(
        "Camera Error",
        "Failed to capture photo: Please try again",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> getCurrentLocation() async {
    if (isLoadingLocation.value) return;
    final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return;
    }

    isLoadingLocation.value = true;

    try {
      // 1. Fetch office location from API
      final officeResponse = await http.get(
        Uri.parse(
          'https://official.solarvision-cairo.com/GetOfficeLoc?CompanyId=1',
        ),
      );
      if (officeResponse.statusCode != 200) {
        Get.snackbar(
          "Office Location Error",
          "Failed to fetch office location from server.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
        isLocationVerified.value = false;
        isLoadingLocation.value = false;
        return;
      }
      final officeList = jsonDecode(officeResponse.body);
      if (officeList is! List || officeList.isEmpty) {
        Get.snackbar(
          "Office Location Error",
          "No office location data received.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
        isLocationVerified.value = false;
        isLoadingLocation.value = false;
        return;
      }
      final office = officeList[0];
      final officeLat = double.tryParse(office['latitude'].toString());
      final officeLng = double.tryParse(office['longitude'].toString());
      final officeRadius = double.tryParse(office['radius'].toString()) ?? 50.0;
      if (officeLat == null || officeLng == null) {
        Get.snackbar(
          "Office Location Error",
          "Invalid office coordinates received.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
        isLocationVerified.value = false;
        isLoadingLocation.value = false;
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          "Location Service Disabled",
          "Please enable location services to continue",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.location_off, color: Colors.white),
          duration: const Duration(seconds: 3),
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
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 4),
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
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      currentPosition.value = position;

      // 2. Compare current location to office location (within 200 meters)
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLat,
        officeLng,
      );
      print(
        'Distance to office: [32m${distance.toStringAsFixed(2)} meters[0m',
      );
      if (distance <= officeRadius!) {
        isLocationVerified.value = true;
        Get.snackbar(
          "Location Verified",
          "GPS location verified successfully (within office range)",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.location_on, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      } else {
        isLocationVerified.value = false;
        Get.snackbar(
          "Out of Range",
          "You are not within the allowed office location range.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.location_off, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }

      print(
        'Location obtained: [34m${position.latitude}, ${position.longitude}[0m',
      );
    } catch (e) {
      print('Location error: $e');
      isLocationVerified.value = false;
      currentPosition.value = null;

      Get.snackbar(
        "Location Error",
        "Failed to get location: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
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

  Future<bool> markAttendance(String type) async {
    final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return false;
    }
    if (isProcessingAttendance.value) {
      print('Already processing attendance request');
      return false;
    }

    try {
      isProcessingAttendance.value = true;

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

      // Get user credentials
      final userId = profileController.userModel.value?.userId;
      final authToken = await getAuthToken();

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

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(attendanceApiUrl));

      // Add headers
      if (authToken != null && authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
        print('Authorization token added');
      }
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['UserId'] = userId;
      request.fields['Type'] = type;
      request.fields['Latitude'] = currentPosition.value!.latitude.toString();
      request.fields['Longitude'] = currentPosition.value!.longitude.toString();
      request.fields['SelfieBase64'] = imageBase64;
      request.fields['EntryTimestamp'] = DateTime.now().toIso8601String();
      if (type == 'out') {
        request.fields['ExitTimestamp'] = DateTime.now().toIso8601String();
      }

      // Add file upload
      var multipartFile = await http.MultipartFile.fromPath(
        'SelfieFile',
        capturedImage.value!.path,
        filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      print('=== Attendance Request ===');
      print('User ID: $userId');
      print('Type: $type');
      print('Latitude: ${currentPosition.value!.latitude}');
      print('Longitude: ${currentPosition.value!.longitude}');
      print('Base64 length: ${imageBase64.length}');
      print('File path: ${capturedImage.value!.path}');
      print('Entry Timestamp: ${request.fields['EntryTimestamp']}');
      if (type == 'out') {
        print('Exit Timestamp: ${request.fields['ExitTimestamp']}');
      }

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('=== API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Attendance marked successfully');
        return true;
      } else {
        await _handleApiError(response);
        return false;
      }
    } catch (e) {
      print('Exception in markAttendance: $e');
      _showError(
        "Network Error",
        "Failed to connect to server: ${e.toString()}",
      );
      return false;
    } finally {
      isProcessingAttendance.value = false;
    }
  }

  Future<void> _handleApiError(http.Response response) async {
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
        } else {
          errorMessage = response.body;
        }
      } catch (e) {
        print('Error parsing API response: $e');
        errorMessage = "Server error: ${response.body}";
      }
    }

    print('API Error: $errorMessage');
    _showError("Attendance Failed", errorMessage);
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(10),
    );
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
    );
  }

  Future<void> clockIn() async {
    if (isProcessingAttendance.value) return;

    print('Attempting to clock in...');
    final success = await markAttendance('in');

    if (success) {
      isClockedIn.value = true;
      profileController.userModel.value?.clockStatus = true;
      dashboardController
          .fetchDashboardData(); // Update dashboard data after clock in
      clockInTime = DateTime.now();
      lastAction.value = "Clocked IN at ${formatTime(clockInTime!)}";

      _showSuccess("Clock In Successful", "Welcome! Your shift has started");

      // Clear captured image after successful attendance
      capturedImage.value = null;
      print('Clock in completed successfully');
    }
  }

  Future<void> clockOut() async {
    if (isProcessingAttendance.value) return;

    print('Attempting to clock out...');
    final success = await markAttendance('out');

    if (success) {
      isClockedIn.value = false;
      profileController.userModel.value?.clockStatus = false;
      clockOutTime = DateTime.now();
      // dashboardController.fetchDashboardData();
      lastAction.value = "Clocked OUT at ${formatTime(clockOutTime!)}";

      _showSuccess(
        "Clock Out Successful",
        "Have a great day! Your shift has ended",
      );

      // Clear captured image after successful attendance
      capturedImage.value = null;
      print('Clock out completed successfully');
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
