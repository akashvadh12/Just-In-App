import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:security_guard/core/theme/app_colors.dart';

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

  // Location management
  RxList patrolLocations = <dynamic>[].obs;
  RxList completedPatrols = <String>[].obs;
  Rx<dynamic> currentPatrolLocation = Rxn<dynamic>();
  RxBool isManualPatrol = false.obs;
  RxBool isQRScanned = false.obs;

  // Location verification
  final isLocationVerified = false.obs;
  final isVerifying = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLocation();
    // Load initial patrol locations
    patrolLocations.addAll([
      {'id': '1', 'name': 'Main Gate', 'latitude': 21.9779517, 'longitude': 82.164835, 'address': 'Main Gate Address'},
      {'id': '2', 'name': 'Backyard', 'latitude': 37.4229999, 'longitude': -122.0850575, 'address': 'Backyard Address'},
      {'id': '3', 'name': 'Warehouse Entry', 'latitude': 37.4239999, 'longitude': -122.0860575, 'address': 'Warehouse Entry Address'},
      {'id': '4', 'name': 'Parking Lot', 'latitude': 37.4249999, 'longitude': -122.0870575, 'address': 'Parking Lot Address'},
    ]);
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

  void refreshPatrolLocations() {
    // Simulate refreshing patrol locations
    patrolLocations.refresh();
  }

  void startPatrolForLocation(dynamic location) {
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
      if (!completedPatrols.contains(patrolLocations[i]['id'])) {
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
    currentPatrolLocation.value['latitude'], 
    currentPatrolLocation.value['longitude'],
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
      completedPatrols.add(currentPatrolLocation.value['id']);
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
    return '${currentPatrolLocation.value['latitude']}, ${currentPatrolLocation.value['longitude']}';
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
