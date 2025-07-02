import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/home/controllers/home_controller.dart';
import 'package:security_guard/modules/issue/issue_list/controller/issue_controller.dart';
import 'package:security_guard/modules/issue/issue_list/issue_view/issue_screen.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/shared/widgets/Custom_Snackbar/Custom_Snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IncidentReportController extends GetxController {
  final descriptionController = TextEditingController();
  final characterCount = 0.obs;
  final maxCharacters = 500;
  final selectedPhotos = <XFile>[].obs;
  final imageBytesList = <Uint8List>[].obs;
  final currentPosition = Rxn<LatLng>();
  final mapController = MapController();
  final isLoading = false.obs;
  final LocalStorageService localStorageService =
      Get.find<LocalStorageService>();
  final HomeController dashboardController = Get.find<HomeController>();

  final IssuesController issuesController = Get.find<IssuesController>();

  @override
  void onInit() {
    super.onInit();
    descriptionController.addListener(_updateCount);
    _fetchCurrentLocation();
  }

  void _updateCount() {
    characterCount.value = descriptionController.text.length;
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        CustomSnackbar.showError(
          "Location Error",
          "Location services are disabled",
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        CustomSnackbar.showError(
          "Location Error",
          "Location permission denied",
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = LatLng(position.latitude, position.longitude);
    } catch (e) {
      CustomSnackbar.showError("Location Error", "Could not get location: $e");
    }
  }

  // Updated method name to match UI call
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        selectedPhotos.add(image);
        if (kIsWeb) {
          Uint8List bytes = await image.readAsBytes();
          imageBytesList.add(bytes);
        }
      }
    } on PlatformException catch (e) {
      CustomSnackbar.showError(
        "Image Picker Error",
        "Failed to pick image: $e",
      );
    } catch (e) {
      CustomSnackbar.showError("Error", "Unexpected error: $e");
    }
  }

  // Method to pick multiple images
  Future<void> pickMultipleImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);

      if (images.isNotEmpty) {
        selectedPhotos.addAll(images);
        if (kIsWeb) {
          for (var image in images) {
            Uint8List bytes = await image.readAsBytes();
            imageBytesList.add(bytes);
          }
        }
      }
    } on PlatformException catch (e) {
      CustomSnackbar.showError(
        "Image Picker Error",
        "Failed to pick images: $e",
      );
    } catch (e) {
      CustomSnackbar.showError("Error", "Unexpected error: $e");
    }
  }

  // Method to remove a photo
  void removePhoto(XFile photo) {
    selectedPhotos.remove(photo);
  }

  Future<String?> getUserId() async {
    try {
      final profileController = Get.find<ProfileController>();
      return profileController.userModel.value?.userId;
    } catch (e) {
      print('Error retrieving user ID: $e');
      return null;
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      return localStorageService.getDeviceToken();
    } catch (e) {
      print('Error retrieving device token: $e');
      return null;
    }
  }

  // Updated method name to match UI call
  Future<void> submitIncidentReport() async {
        final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return ;
    }
    final description = descriptionController.text.trim();
    final position = currentPosition.value;

    // Validation

    if (position == null) {
      CustomSnackbar.showError(
        'Validation Error',
        'Location is required. Please enable location services.',
      );
      return;
    }

    if (selectedPhotos.isEmpty ) {
      CustomSnackbar.showError(
        'Validation Error',
        'Please provide a attach images.',
      );
      return;
    }

    if (description.toString().trim().isEmpty) {
      CustomSnackbar.showError(
        'Validation Error',
        'Please provide a description of the incident.',
      );
      return;
    }

    final userId = await getUserId();
    final token = await getDeviceToken();

    print("user token👍👍 : $token, user👍👍 : $userId");
    if (userId == null) {
      CustomSnackbar.showError('Unauthorized', 'Please login to continue.');
      return;
    }

    isLoading.value = true;

    final uri = Uri.parse(
      "https://official.solarvision-cairo.com/api/IssuesRecord/create",
    );
    final headers = {'Authorization': 'Bearer $token'};

    try {
      await _submitWithImages(uri, headers, userId, position, description);
    } catch (e) {
      CustomSnackbar.showError("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _submitWithImages(
    Uri uri,
    Map<String, String> headers,
    String userId,
    LatLng position,
    String description,
  ) async {
    final request =
        http.MultipartRequest("POST", uri)
          ..headers.addAll(headers)
          ..fields['userId'] = userId
          ..fields['latitude'] = position.latitude.toString()
          ..fields['longitude'] = position.longitude.toString()
          ..fields['description'] = description;

    for (var photo in selectedPhotos) {
      final mimeType = lookupMimeType(photo.path) ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);
      final file = await http.MultipartFile.fromPath(
        'images',
        photo.path,
        filename: path.basename(photo.path),
        contentType: mediaType,
      );
      request.files.add(file);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    _handleResponse(response);
  }

  void _handleResponse(http.Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final responseData = jsonDecode(response.body);
        final issueId =
            responseData['id']; // Adjust key if it's nested or named differently

        // Save issueId to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_issue_id', issueId.toString());

        debugPrint("✅ Report submitted! Issue ID saved: $issueId");

        // CustomSnackbar.showSuccess(
        //   '✅ Success',
        //   'Report submitted successfully!',
        // );
        _resetForm();

        // Show success dialog
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  '✅ Report Submitted!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your incident report has been successfully submitted and is being reviewed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.back();
                    issuesController.refreshIssues();
                    dashboardController.fetchDashboardData();
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      } catch (e) {
        debugPrint("⚠️ Error parsing response or saving issue ID: $e");
      }
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to submit report';

        debugPrint(
          "❌ Submission failed (Status: ${response.statusCode}) - $errorMessage",
        );

        CustomSnackbar.showError('❌ Submission Failed', errorMessage);
      } catch (e) {
        debugPrint(
          "🚨 Server error while submitting report (Status: ${response.statusCode})",
        );

        CustomSnackbar.showError(
          '❌ Submission Failed',
          'Server error: ${response.statusCode}',
        );
      }
    }
  }

  void _resetForm() {
    descriptionController.clear();
    selectedPhotos.clear();
    characterCount.value = 0;
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}
