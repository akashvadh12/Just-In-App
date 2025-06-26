import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/home/controllers/home_controller.dart';
import 'package:security_guard/modules/petrol/views/qr_scanner_view.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/navigation_controller.dart';

class PatrolLocation {
  final String locationId;
  final String locationName;
  final double latitude;
  final double longitude;
  final String barcodeUrl;
  final double radius;
  final bool status;

  PatrolLocation({
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.barcodeUrl,
    required this.status,
    this.radius = 50.0, // Default radius in meters
  });

  factory PatrolLocation.fromJson(Map<String, dynamic> json) {
    return PatrolLocation(
      locationId: json['locationId'] ?? '',
      locationName: json['locationName'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      barcodeUrl: json['barcodeUrl'] ?? '',
      radius: double.tryParse(json['radius'].toString()) ?? 50.0,
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'barcodeUrl': barcodeUrl,
      'status': status,
      'radius': radius,
    };
  }
}

class PatrolCheckInController extends GetxController {
  final currentStep = 1.obs;
  final currentLatLng = Rxn<LatLng>();
  final mapController = MapController();
  final isMapReady = false.obs;
  final notes = ''.obs;

  // Camera functionality
  final ImagePicker _picker = ImagePicker();
  final Rxn<File> capturedImage = Rxn<File>();
  final isFlashOn = false.obs;

  // QR code result
  final qrResult = Rxn<String>();

  // Location management - Updated to use PatrolLocation model
  RxList<PatrolLocation> patrolLocations = <PatrolLocation>[].obs;
  RxList<String> completedPatrols = <String>[].obs;
  Rx<PatrolLocation?> currentPatrolLocation = Rxn<PatrolLocation?>();
  RxBool isManualPatrol = false.obs;
  RxBool isQRScanned = false.obs;

  ProfileController profileController = Get.find<ProfileController>();
  final HomeController homeController = Get.find<HomeController>();
  final BottomNavController bottomNavController =
      Get.find<BottomNavController>();

  // Location verification
  final isLocationVerified = false.obs;
  final isVerifying = false.obs;

  // API loading state
  final isLoadingLocations = false.obs;
  final isVerifyingLocation = false.obs;

  // API endpoint
  static const String _apiUrl =
      'https://official.solarvision-cairo.com/patrol/get-all-locations';

  // Add a variable to store the last scanned QR data and status
  final scannedQRData = ''.obs;
  final qrScanError = ''.obs;
  final isQRMatched = false.obs;
  PatrolLocation? matchedLocation;

  // Add a variable for userId (replace with actual user logic as needed)
  // final String userId = '202408056';

  // Add a variable for generated logId
  String generateLogId() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  final TextEditingController remarksController = TextEditingController();
  final RxBool isLoading = false.obs;
  final lastPatrolStatus = ''.obs;

  // // Replace with actual user ID from your auth system
  // String get userID => "202408056"; // This should come from your user session

  @override
  void onClose() {
    remarksController.dispose();
    super.onClose();
  }

  Future<void> stopPatrol() async {
    final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return;
    }

    try {
      isLoading.value = true;
      lastPatrolStatus.value = '';

      final response = await _callStopPatrolAPI();

      if (response['success']) {
        lastPatrolStatus.value = response['message'];
        await _handleSuccessfulStop(response);
        remarksController.clear();
      } else {
        lastPatrolStatus.value =
            'No active patrol session found for this user.';
      }
    } catch (e) {
      lastPatrolStatus.value = 'Error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _callStopPatrolAPI() async {
    try {
      final url = Uri.parse(
        'https://official.solarvision-cairo.com/patrol/checkout',
      );

      final requestBody = {
        "userID": profileController.userModel.value?.userId ?? '',
        "remarks":
            remarksController.text.trim().isEmpty
                ? "Patrol stopped"
                : remarksController.text.trim(),
      };

      print('Sending request: ${json.encode(requestBody)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              // Add any additional headers like authorization if needed
              // 'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Patrol stopped successfully',
          'endLocation': responseData['endLocation'],
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'error': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _handleSuccessfulStop(Map<String, dynamic> response) async {
    // Reset current patrol state
    resetCurrentPatrol();

    // Save patrol end information
    await _savePatrolEndInfo(response);

    // Show success dialog
    _showSuccessDialog(response);

    // Optional: Navigate back or to a specific screen
    // Get.back();
    // or
    // Get.offAllNamed('/home');
  }

  Future<void> _savePatrolEndInfo(Map<String, dynamic> response) async {
    // Save to local storage or send to local database
    // This is where you'd typically save the patrol end information
    print('Saving patrol end info: ${response['data']}');

    // Example: Save to shared preferences or local database
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('lastPatrolEnd', json.encode(response['data']));
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Patrol Stopped'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(response['message']),
            if (response['endLocation'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'End Location: ${response['endLocation']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              lastPatrolStatus.value = '';
              fetchPatrolLocationsFromAPI(isRefresh: true);
              Get.back();
              homeController.fetchDashboardData();
              bottomNavController.changeTab(0);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    fetchLocation();
    fetchPatrolLocationsFromAPI();
  }

  // New method to fetch patrol locations from API
  Future<void> fetchPatrolLocationsFromAPI({isRefresh = false}) async {
    try {
      isLoadingLocations.value = true;

      // Check if user profile is loaded
      if (profileController.userModel.value == null) {
        Get.snackbar(
          'Error',
          'User profile not loaded',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // If logId exists, fetch patrol history for that logId
      final logId = profileController.userModel.value!.logId;
      http.Response response;

      if (logId != null && logId.isNotEmpty && !isRefresh) {
        final url =
            'https://official.solarvision-cairo.com/patrol/history?logId=$logId';
        response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 30));
      } else {
        // Otherwise, fetch all patrol locations
        response = await http
            .get(
              Uri.parse(
                "https://official.solarvision-cairo.com/patrol/history",
              ),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 30));
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<PatrolLocation> locations =
            jsonData.map((json) => PatrolLocation.fromJson(json)).toList();

        patrolLocations.clear();
        patrolLocations.addAll(locations);

        completedPatrols.clear();
        for (final loc in locations) {
          if (loc.status) {
            completedPatrols.add(loc.locationId);
          }
        }

        // Get.snackbar(
        //   'Success',
        //   'Patrol locations loaded successfully',
        //   backgroundColor: AppColors.greenColor,
        //   colorText: Colors.white,
        //   duration: const Duration(seconds: 2),
        // );
      } else {
        throw Exception(
          'Failed to load patrol locations: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Fallback to hardcoded locations if API fails
      _loadFallbackLocations();

      Get.snackbar(
        'API Error',
        'Failed to load locations from server. Using offline data.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      print('Error fetching patrol locations: $e');
    } finally {
      isLoadingLocations.value = false;
    }
  }

  // Fallback method with hardcoded locations
  void _loadFallbackLocations() {
    final fallbackLocations = [
      PatrolLocation(
        locationId: '1',
        locationName: 'Main Gate',
        latitude: 21.9779517,
        longitude: 82.164835,
        barcodeUrl: '',
        status: false,
      ),
      PatrolLocation(
        locationId: '2',
        locationName: 'Backyard',
        latitude: 37.4229999,
        longitude: -122.0850575,
        barcodeUrl: '',
        status: false,
      ),
      PatrolLocation(
        locationId: '3',
        locationName: 'Warehouse Entry',
        latitude: 37.4239999,
        longitude: -122.0860575,
        barcodeUrl: '',
        status: false,
      ),
      PatrolLocation(
        locationId: '4',
        locationName: 'Parking Lot',
        latitude: 37.4249999,
        longitude: -122.0870575,
        barcodeUrl: '',
        status: false,
      ),
    ];

    patrolLocations.clear();
    patrolLocations.addAll(fallbackLocations);
  }

  Future<void> fetchLocation() async {
    final locationPermission = await Permission.location.request();
    if (!locationPermission.isGranted) {
      Get.snackbar(
        'Permission Denied',
        'Location permission is required for patrol check-in',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    currentLatLng.value = latLng;

    if (isMapReady.value) {
      mapController.move(latLng, 16);
    } else {
      Future.delayed(Duration.zero, () {
        if (isMapReady.value && currentLatLng.value != null) {
          mapController.move(currentLatLng.value!, 16);
        }
      });
    }
  }

  void onMapReady() {
    isMapReady.value = true;
    if (currentLatLng.value != null) {
      mapController.move(currentLatLng.value!, 16);
    }
  }

  // Updated refresh method to fetch from API
  Future<void> refreshPatrolLocations() async {
    await fetchPatrolLocationsFromAPI();
  }

  void startPatrolForLocation(PatrolLocation location) {
    currentPatrolLocation.value = location;
    currentStep.value = 1;
    isManualPatrol.value = false;
    isLocationVerified.value = false;
    isQRScanned.value = false;
  }

  void addManualPatrol() {
    isManualPatrol.value = true;
    currentPatrolLocation.value = null;
    currentStep.value = 1;
    isLocationVerified.value = false;
    isQRScanned.value = false;
  }

  int getNextPatrolIndex() {
    for (int i = 0; i < patrolLocations.length; i++) {
      if (!completedPatrols.contains(patrolLocations[i].locationId)) {
        return i;
      }
    }
    return -1;
  }

  String getCurrentStepTitle() {
    switch (currentStep.value) {
      case 1:
        return 'Verify';
      case 2:
        return isManualPatrol.value ? 'Photo' : 'QR Scan';
      case 3:
        return isManualPatrol.value ? 'Notes' : 'Photo';
      case 4:
        return isManualPatrol.value ? 'Submit' : 'Notes';
      case 5:
        return 'Submit';
      default:
        return '';
    }
  }

  void goToNextStep() {
    if (currentStep.value < 5) {
      currentStep.value++;
    }
  }

  Future<void> verifyLocation() async {
    isVerifyingLocation.value = true;
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
      isVerifyingLocation.value = false;
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
      isVerifyingLocation.value = false;
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
      isVerifyingLocation.value = false;
      return;
    }

    if (currentLatLng.value == null) {
      Get.snackbar(
        'Error',
        'Cannot verify: Current location not available',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      isVerifyingLocation.value = false;
      return;
    }

    isVerifyingLocation.value = true;

    // Simulate verification process
    await Future.delayed(Duration(seconds: 2));

    if (currentPatrolLocation.value != null) {
      final distance = Geolocator.distanceBetween(
        currentLatLng.value!.latitude,
        currentLatLng.value!.longitude,
        currentPatrolLocation.value!.latitude,
        currentPatrolLocation.value!.longitude,
      );

      if (distance <= currentPatrolLocation.value!.radius) {
        isLocationVerified.value = true;
        Get.snackbar(
          'Verified',
          'You are within the checkpoint area',
          backgroundColor: AppColors.greenColor,
          colorText: Colors.white,
        );
        isVerifyingLocation.value = false;
        goToNextStep();
      } else {
        isLocationVerified.value = false;
        isVerifyingLocation.value = false;
        Get.snackbar(
          'Verification Failed',
          'You are not within the checkpoint area (${distance.toStringAsFixed(0)}m away)',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } else {
      isLocationVerified.value = true;
      Get.snackbar(
        'Location Captured',
        'Current location has been recorded',
        backgroundColor: AppColors.greenColor,
        colorText: Colors.white,
      );
      isVerifyingLocation.value = false;
      goToNextStep();
    }

    isVerifying.value = false;
  }

  // Parse QR code, match location, and start patrol
  void handleScannedQRCode(String qrString) {
    scannedQRData.value = qrString;
    qrScanError.value = '';
    isQRMatched.value = false;
    matchedLocation = null;
    try {
      final parts = qrString.split('_');
      if (parts.length != 4) {
        qrScanError.value = 'Invalid QR format';
        return;
      }
      final locationId = parts[0];
      // Find location in patrolLocations
      final found = patrolLocations.firstWhereOrNull(
        (loc) => loc.locationId == locationId,
      );
      if (found != null) {
        // Check if patrol already completed for this location
        if (completedPatrols.contains(locationId)) {
          qrScanError.value = 'Patrol already submitted for this location.';
          isQRMatched.value = false;
          return;
        }
        matchedLocation = found;
        isQRMatched.value = true;
        // Start patrol for this location
        startPatrolForLocation(found);
        // Optionally update lat/lng if needed
      } else {
        qrScanError.value = 'Location not found in patrol list.';
      }
    } catch (e) {
      qrScanError.value = 'Error parsing QR: $e';
    }
  }

  // Update openQRScanner to use handleScannedQRCode
  void openQRScanner({VoidCallback? onSuccess}) async {
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      Get.snackbar(
        'Permission Denied',
        'Camera permission is required for QR scanning',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }
    print('QR Code Scanned: Waiting for QR scanner to open...');
    Get.to(
      () => QRScannerView(
        onQRViewCreated: (QRViewController controller) {
          controller.scannedDataStream.listen((scanData) {
            if (scanData.code != null) {
              qrResult.value = scanData.code;
              isQRScanned.value = true;
              handleScannedQRCode(scanData.code!);

              print('QR Code Scanned: ${scanData.code}');
              Get.back();
              // Get.snackbar(
              //   'Success',
              //   'QR Code Scanned',
              //   backgroundColor: AppColors.greenColor,
              //   colorText: Colors.white,
              // );
              if (isQRMatched.value) {
                // Check if patrol already completed for this location
                final locationId = matchedLocation?.locationId;
                if (locationId != null &&
                    !completedPatrols.contains(locationId)) {
                  // goToNextStep();

                  if (onSuccess != null) onSuccess();
                }
              }
            }
          });
        },
      ),
    );
  }

  // Update submitPatrolReport to call the check-in API
  Future<void> submitPatrolReport() async {
    if (capturedImage.value != null) {
      final locationId =
          isManualPatrol.value
              ? 'manual'
              : (matchedLocation?.locationId ??
                  currentPatrolLocation.value?.locationId ??
                  '');
      final latitude =
          isManualPatrol.value
              ? (currentLatLng.value?.latitude ?? 0.0).toString()
              : (matchedLocation?.latitude.toString() ??
                  currentPatrolLocation.value?.latitude.toString() ??
                  '');
      final longitude =
          isManualPatrol.value
              ? (currentLatLng.value?.longitude ?? 0.0).toString()
              : (matchedLocation?.longitude.toString() ??
                  currentPatrolLocation.value?.longitude.toString() ??
                  '');
      final note = notes.value;
      final imageFile = capturedImage.value;

      // Determine if this is the last patrol
      int completedCount = completedPatrols.length;
      String? submittingLocationId = currentPatrolLocation.value?.locationId;
      bool isAlreadyCompleted =
          submittingLocationId != null &&
          completedPatrols.contains(submittingLocationId);
      int totalLocations = patrolLocations.length;
      bool isLastPatrol =
          !isAlreadyCompleted && (completedCount + 1) >= totalLocations;

      final url = Uri.parse(
        'https://official.solarvision-cairo.com/patrol/checkin',
      );
      try {
        final request =
            http.MultipartRequest('POST', url)
              ..fields['UserID'] = profileController.userModel.value!.userId
              ..fields['Log_Id'] =
                  profileController.userModel.value!.logId ?? ""
              ..fields['LocationId'] = locationId
              ..fields['Latitude'] = latitude
              ..fields['Longitude'] = longitude
              ..fields['Note'] = note
              ..fields['ActivePatrol'] = isLastPatrol ? 'false' : 'true';
        if (imageFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath('Selfie', imageFile.path),
          );
        }
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200) {
          final respJson = json.decode(response.body);
          profileController.userModel.value!.logId =
              respJson['checkInId'] ?? profileController.userModel.value!.logId;
          Get.snackbar(
            'Success',
            respJson['message'] ?? 'Patrol report submitted successfully',
            backgroundColor: AppColors.greenColor,
            colorText: Colors.white,
          );
          if (currentPatrolLocation.value != null) {
            completedPatrols.add(currentPatrolLocation.value!.locationId);
          }
          resetCurrentPatrol();
        } else {
          Get.snackbar(
            'Error',
            'Failed to submit patrol report: ${response.body}',
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to submit patrol report: $e',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Please complete all steps (QR scan and photo required)',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  // Add Manual Patrol API
  Future<void> addManualPatrolApi({
    required String manualLocationName,
    required double manualLatitude,
    required double manualLongitude,
    required File selfie,
    required String note,
    // required String logId,
  }) async {
    final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return;
    }
    isLoading.value = true;
    try {
      final url = Uri.parse(
        'https://official.solarvision-cairo.com/patrol/unknown-checkin',
      );
      final userId = profileController.userModel.value?.userId ?? '';
      final request =
          http.MultipartRequest('POST', url)
            ..fields['UserID'] = userId
            ..fields['ManualLocationName'] = manualLocationName
            ..fields['ManualLatitude'] = manualLatitude.toString()
            ..fields['ManualLongitude'] = manualLongitude.toString()
            ..fields['Log_Id'] = profileController.userModel.value!.logId!
            ..fields['Note'] = note
            ..fields['ActivePatrol'] = 'true'
            ..fields['LocationId'] = '';
      request.files.add(
        await http.MultipartFile.fromPath(
          'Selfie',
          selfie.path,
          contentType: MediaType('image', 'png'),
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final respJson = json.decode(response.body);
        Get.snackbar(
          'Success',
          respJson['message'] ?? 'Manual patrol added successfully.',
          backgroundColor: AppColors.greenColor,
          colorText: Colors.white,
        );
        // Optionally reset state or update UI
        resetCurrentPatrol();
      } else {
        Get.snackbar(
          'Error',
          'Failed to add manual patrol: ${response.body}',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add manual patrol: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void resetCurrentPatrol() {
    currentStep.value = 1;
    currentPatrolLocation.value = null;
    isManualPatrol.value = false;
    isLocationVerified.value = false;
    isQRScanned.value = false;
    notes.value = '';
    capturedImage.value = null;
  }

  // Utility: Get current GPS as string
  String getCurrentGPSString() {
    if (currentLatLng.value != null) {
      return '${currentLatLng.value!.latitude}, ${currentLatLng.value!.longitude}';
    }
    return 'Unknown';
  }

  // Utility: Get target GPS as string
  String getTargetGPSString() {
    if (currentPatrolLocation.value != null) {
      return '${currentPatrolLocation.value!.latitude}, ${currentPatrolLocation.value!.longitude}';
    }
    return 'Unknown';
  }

  // Cancel patrol and reset state
  void cancelCurrentPatrol() {
    resetCurrentPatrol();
    // Optionally, pop the current screen if needed
    // Get.back();
  }

  // Toggle camera flash
  void toggleFlash() {
    isFlashOn.value = !isFlashOn.value;
  }

  // Take a picture using the camera
  Future<void> takePicture() async {
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      Get.snackbar(
        'Permission Denied',
        'Camera permission is required for taking photos',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
      );
      if (photo != null) {
        capturedImage.value = File(photo.path);
      }
    } catch (e) {
      Get.snackbar(
        'Camera Error',
        'Failed to capture image: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  // Retake photo (clear current image)
  void retakePhoto() {
    capturedImage.value = null;
  }
}
