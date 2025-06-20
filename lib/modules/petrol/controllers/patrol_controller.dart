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

class PatrolLocation {
  final String locationId;
  final String locationName;
  final double latitude;
  final double longitude;
  final String barcodeUrl;
  final bool status;

  PatrolLocation({
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.barcodeUrl,
    required this.status,
  });

  factory PatrolLocation.fromJson(Map<String, dynamic> json) {
    return PatrolLocation(
      locationId: json['locationId'] ?? '',
      locationName: json['locationName'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      barcodeUrl: json['barcodeUrl'] ?? '',
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

  // Location verification
  final isLocationVerified = false.obs;
  final isVerifying = false.obs;

  // API loading state
  final isLoadingLocations = false.obs;

  // API endpoint
  static const String _apiUrl = 'https://official.solarvision-cairo.com/patrol/get-all-locations';

  @override
  void onInit() {
    super.onInit();
    fetchLocation();
    fetchPatrolLocationsFromAPI();
  }

  // New method to fetch patrol locations from API
  Future<void> fetchPatrolLocationsFromAPI() async {
    try {
      isLoadingLocations.value = true;
      
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<PatrolLocation> locations = jsonData
            .map((json) => PatrolLocation.fromJson(json))
            .toList();
        
        patrolLocations.clear();
        patrolLocations.addAll(locations);
        
        Get.snackbar(
          'Success',
          'Patrol locations loaded successfully',
          backgroundColor: AppColors.greenColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        throw Exception('Failed to load patrol locations: ${response.statusCode}');
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
    if (currentStep.value < (isManualPatrol.value ? 4 : 5)) {
      currentStep.value++;
    }
  }

  Future<void> verifyLocation() async {
    if (currentLatLng.value == null) {
      Get.snackbar(
        'Error',
        'Cannot verify: Current location not available',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    isVerifying.value = true;

    // Simulate verification process
    await Future.delayed(Duration(seconds: 2));

    if (currentPatrolLocation.value != null) {
      final distance = Geolocator.distanceBetween(
        currentLatLng.value!.latitude,
        currentLatLng.value!.longitude,
        currentPatrolLocation.value!.latitude,
        currentPatrolLocation.value!.longitude,
      );

      if (distance <= 50) {
        isLocationVerified.value = true;
        Get.snackbar(
          'Verified',
          'You are within the checkpoint area',
          backgroundColor: AppColors.greenColor,
          colorText: Colors.white,
        );
        goToNextStep();
      } else {
        isLocationVerified.value = false;
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
      goToNextStep();
    }

    isVerifying.value = false;
  }

  void openQRScanner() async {
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

    Get.to(
      () => QRScannerView(
        onQRViewCreated: (QRViewController controller) {
          controller.scannedDataStream.listen((scanData) {
            if (scanData.code != null) {
              qrResult.value = scanData.code;
              isQRScanned.value = true;
              Get.back();
              Get.snackbar(
                'Success',
                'QR Code Scanned',
                backgroundColor: AppColors.greenColor,
                colorText: Colors.white,
              );
              goToNextStep();
            }
          });
        },
      ),
    );
  }

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
        goToNextStep();
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

  void toggleFlash() {
    isFlashOn.toggle();
    Get.snackbar(
      'Flash',
      isFlashOn.value ? 'Flash turned on' : 'Flash turned off',
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  void retakePhoto() {
    capturedImage.value = null;
  }

  void submitPatrolReport() {
    if (isManualPatrol.value || isQRScanned.value) {
      Get.snackbar(
        'Success',
        'Patrol report submitted successfully',
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
        'Please complete all steps',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void cancelCurrentPatrol() {
    resetCurrentPatrol();
    Get.back();
  }

  void resetCurrentPatrol() {
    currentStep.value = 1;
    isLocationVerified.value = false;
    isQRScanned.value = false;
    capturedImage.value = null;
    notes.value = '';
    currentPatrolLocation.value = null;
  }

  String getCurrentGPSString() {
    if (currentLatLng.value != null) {
      return '${currentLatLng.value!.latitude}, ${currentLatLng.value!.longitude}';
    }
    return 'Unknown';
  }

  String getTargetGPSString() {
    if (currentPatrolLocation.value != null) {
      return '${currentPatrolLocation.value!.latitude}, ${currentPatrolLocation.value!.longitude}';
    }
    return 'Unknown';
  }
}

class QRScannerView extends StatelessWidget {
  final Function(QRViewController) onQRViewCreated;

  const QRScannerView({required this.onQRViewCreated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: GlobalKey(debugLabel: 'QR'),
              onQRViewCreated: onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Scan the QR code at the checkpoint',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}