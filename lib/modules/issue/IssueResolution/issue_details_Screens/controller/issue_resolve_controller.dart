import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:security_guard/core/api/api_service.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssueDetailController extends GetxController {
  final Rx<Issue?> currentIssue = Rx<Issue?>(null);
  final RxList<File> selectedImages = <File>[].obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxString errorMessage = ''.obs;
// Location distance check will be performed in resolveIssue method.
  final LocalStorageService _storage = LocalStorageService.instance;

  late String userId;

  /// Call this in your UI to initialize the controller
  void initializeIssue(Issue issue, String userId) {
    currentIssue.value = issue;
    this.userId = userId;
  }

  @override
  void onInit() {
    super.onInit();
    // Load user ID from local storage
    getCurrentLocation();
  }

  Future<void> pickImages(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        selectedImages.add(File(pickedFile.path));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      errorMessage.value = '';

      final status = await Permission.location.request();
      if (!status.isGranted) {
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition.value = position;
    } catch (e) {
      errorMessage.value = 'Failed to get location: ${e.toString()}';
     Get.snackbar(
          "Location Service Disabled",
          "Please enable location services to continue",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.location_off, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<bool> resolveIssue(String resolutionNote) async {
        final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return false;
    }
    try {
      if (currentIssue.value == null || currentPosition.value == null) {
        throw Exception('Missing required data');
      }
      if (selectedImages.isEmpty) {
         Get.snackbar(
        'No Images Selected',
        'Please select at least one image to resolve the issue.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
        return false;
    
      }

      isLoading.value = true;
      errorMessage.value = '';

      final token = await _storage.getDeviceToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Convert selected images to base64 strings
      final List<String> base64Images = [];
      for (final image in selectedImages) {
        final bytes = await image.readAsBytes();
        base64Images.add(base64Encode(bytes));
      }

      final response = await ApiService().resolveIssue(
        token: token,
        issueId: currentIssue.value!.id,
        userId: userId,
        latitude: currentPosition.value!.latitude,
        longitude: currentPosition.value!.longitude,
        resolutionNote: resolutionNote,
        imageFiles: selectedImages,
      );

      if (response) {
        currentIssue.value = currentIssue.value!.copyWith(
          status: IssueStatus.resolved,
          resolutionNote: resolutionNote,
          resolverName: 'Current User', // You can replace with actual name
          resolvedAt: DateTime.now(),
        );
        return true;
      } else {
        throw Exception('Failed to resolve issue');
      }
    } catch (e) {
      errorMessage.value = 'Error resolving issue: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  
}
