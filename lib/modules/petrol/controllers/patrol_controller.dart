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

  // Selected location
  final selectedLocationIndex = Rxn<int>();
  final selectedLocation = Rxn<String>();

  // Location verification
  final isLocationVerified = false.obs;
  final isVerifying = false.obs;

  final locationOptions = [
    'Main Gate',
    'Backyard',
    'Warehouse Entry',
    'Parking Lot',
  ];

  // Predefined geo-fence coordinates for each location (example values)
  final Map<String, LatLng> locationCoordinates = {
    'Main Gate': LatLng(37.4219999, -122.0840575),
    'Backyard': LatLng(37.4229999, -122.0850575),
    'Warehouse Entry': LatLng(37.4239999, -122.0860575),
    'Parking Lot': LatLng(37.4249999, -122.0870575),
  };

  @override
  void onInit() {
    super.onInit();
    fetchLocation();
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

  void updateLocationFromTap(LatLng point) {
    currentLatLng.value = point;
    // Reset verification when location changes
    isLocationVerified.value = false;
  }

  // QR Code Scanner
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

              // Check if scanned QR matches any location
              final locationEntry = locationCoordinates.entries.firstWhere(
                (entry) => entry.key == scanData.code,
                orElse: () => const MapEntry<String, LatLng>("", LatLng(0, 0)),
              );

              if (locationEntry.key.isNotEmpty) {
                selectedLocation.value = locationEntry.key;
                currentLatLng.value = locationEntry.value;

                if (isMapReady.value) {
                  mapController.move(locationEntry.value, 16);
                }

                // Find and set index
                final index = locationOptions.indexOf(locationEntry.key);
                if (index != -1) {
                  selectedLocationIndex.value = index;
                }

                Get.back(); // Close scanner
                Get.snackbar(
                  'Success',
                  'Location found: ${locationEntry.key}',
                  backgroundColor: AppColors.secondary,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Invalid QR Code',
                  'This QR code is not associated with any patrol checkpoint',
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }
            }
          });
        },
      ),
    );
  }

  // Manual location selection
  void showLocationSelectionDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: Get.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Checkpoint',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ...List.generate(
                locationOptions.length,
                (index) => ListTile(
                  title: Text(locationOptions[index]),
                  leading: Radio<int>(
                    value: index,
                    groupValue: selectedLocationIndex.value,
                    onChanged: (value) {
                      selectedLocationIndex.value = value;
                      selectedLocation.value = locationOptions[index];
                      final latLng =
                          locationCoordinates[locationOptions[index]];
                      if (latLng != null) {
                        currentLatLng.value = latLng;
                        if (isMapReady.value) {
                          mapController.move(latLng, 16);
                        }
                      }
                      isLocationVerified.value = false;
                      Get.back();
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Verify location
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

    // If we have a selected location, check if current position is within range (50 meters)
    if (selectedLocation.value != null) {
      final checkpointLatLng = locationCoordinates[selectedLocation.value];
      if (checkpointLatLng != null) {
        final distance = Geolocator.distanceBetween(
          currentLatLng.value!.latitude,
          currentLatLng.value!.longitude,
          checkpointLatLng.latitude,
          checkpointLatLng.longitude,
        );

        if (distance <= 50) {
          isLocationVerified.value = true;
          Get.snackbar(
            'Verified',
            'You are within the checkpoint area',
            backgroundColor: AppColors.greenColor,
            colorText: Colors.white,
          );
          currentStep.value = 2; // Move to next step
        } else {
          isLocationVerified.value = false;
          Get.snackbar(
            'Verification Failed',
            'You are not within the checkpoint area (${distance.toStringAsFixed(0)}m away)',
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      }
    } else {
      // If no specific checkpoint is selected, just verify we have a location
      isLocationVerified.value = true;
      Get.snackbar(
        'Location Captured',
        'Current location has been recorded',
        backgroundColor: AppColors.greenColor,
        colorText: Colors.white,
      );
      currentStep.value = 2; // Move to next step
    }

    isVerifying.value = false;
  }

  // Camera functions
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
        currentStep.value = 3; // Move to next step
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

  // Submit patrol report
  Future<void> submitReport() async {
    if (!isLocationVerified.value) {
      Get.snackbar(
        'Error',
        'Please verify your location first',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (capturedImage.value == null) {
      Get.snackbar(
        'Error',
        'Please take a photo of the checkpoint',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    // Simulate submitting
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Submitting patrol report...'),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    await Future.delayed(Duration(seconds: 3));

    Get.back(); // Close dialog

    Get.snackbar(
      'Success',
      'Patrol report submitted successfully',
      backgroundColor: AppColors.greenColor,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
    );

    // Reset and go back
    Future.delayed(Duration(seconds: 2), () {
      resetForm();
      Get.back(); // Return to previous screen
    });
  }

  void resetForm() {
    capturedImage.value = null;
    selectedLocation.value = null;
    selectedLocationIndex.value = null;
    isLocationVerified.value = false;
    currentStep.value = 1;
    notes.value = '';
  }
}

// QR Scanner View
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
