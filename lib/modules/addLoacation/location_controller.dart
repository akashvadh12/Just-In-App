import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
class Location {
  final int id;
  final String locationId;
  final String locationName;
  final String latitude;
  final String longitude;
  final String radius;
  final bool status;

  Location({
    required this.id,
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.status,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? 0,
      locationId: json['location_Id']?.toString() ?? '',
      locationName: json['location_Name']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      radius: json['radius']?.toString() ?? '0',
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_Id': locationId,
      'location_Name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'status': status,
    };
  }
}
// ========================= CONTROLLER =========================

class LocationController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final String userId = Get.find<ProfileController>().userModel.value!.userId;
  
  // Observable variables
  RxList<Location> locations = <Location>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSubmitting = false.obs;
  Rx<File?> selectedImage = Rx<File?>(null);
  
  // Base URL
  final String baseUrl = 'https://justin.solarvision-cairo.com/api/Loaction';
  
  @override
  void onInit() {
    super.onInit();
    fetchLocations();
  }

  // Fetch all locations
  Future<void> fetchLocations() async {
    try {
      isLoading(true);
      
      final url = Uri.parse('$baseUrl/all');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        locations.value = data.map((json) => Location.fromJson(json)).toList();
      } else {
        Get.snackbar(
          'Error',
          'Failed to fetch locations: ${response.body}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch locations: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Add new location
  Future<bool> addLocation({
    required String locationName,
    required String latitude,
    required String longitude,
    required String radius,
    File? photo,
  }) async {
    if (locationName.isEmpty || latitude.isEmpty || longitude.isEmpty || radius.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      isSubmitting(true);
      
      final url = Uri.parse('$baseUrl/add');
      final request = http.MultipartRequest('POST', url)
        ..fields['Location_Name'] = locationName
        ..fields['Latitude'] = latitude
        ..fields['Longitude'] = longitude
        ..fields['Radius'] = radius
        ..fields['UserId'] = userId;

      if (photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Photos', photo.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final respJson = json.decode(response.body);
        Get.snackbar(
          'Success',
          respJson['message'] ?? 'Location added successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchLocations(); // Refresh the list
        clearImage(); // Clear selected image after successful submission
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to add location: ${response.body}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add location: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting(false);
    }
  }

  // Update location
  Future<bool> updateLocation({
    required String locationId,
    required String locationName,
    String? latitude,
    String? longitude,
    String? radius,
    File? photo,
  }) async {
    if (locationId.isEmpty || locationName.isEmpty) {
      Get.snackbar(
        'Error',
        'Location ID and name are required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      isSubmitting(true);
      
      final url = Uri.parse('$baseUrl/update');
      final request = http.MultipartRequest('PUT', url)
        ..fields['Location_Id'] = locationId
        ..fields['Location_Name'] = locationName
        ..fields['Latitude'] = latitude ?? ''
        ..fields['Longitude'] = longitude ?? ''
        ..fields['Radius'] = radius ?? ''
        ..fields['UserId'] = userId ?? '';

      if (photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Photos', photo.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final respJson = json.decode(response.body);
        Get.snackbar(
          'Success',
          respJson['message'] ?? 'Location updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchLocations(); // Refresh the list
        clearImage(); // Clear selected image after successful submission
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to update location: ${response.body}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update location: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting(false);
    }
  }

  // Delete location
  Future<bool> deleteLocation(String locationId) async {
    if (locationId.isEmpty) {
      Get.snackbar(
        'Error',
        'Location ID is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      isSubmitting(true);
      
      final url = Uri.parse('$baseUrl/delete/$locationId');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final respJson = json.decode(response.body);
        Get.snackbar(
          'Success',
          respJson['message'] ?? 'Location deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchLocations(); // Refresh the list
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete location: ${response.body}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete location: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting(false);
    }
  }

  // Pick image from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress image to reduce file size
      );
      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Clear selected image
  void clearImage() {
    selectedImage.value = null;
  }

  // Refresh locations
  void refreshLocations() {
    fetchLocations();
  }

  // Get location by ID
  Location? getLocationById(String locationId) {
    try {
      return locations.firstWhere((location) => location.locationId == locationId);
    } catch (e) {
      return null;
    }
  }

  // Check if location exists
  bool locationExists(String locationId) {
    return locations.any((location) => location.locationId == locationId);
  }

  @override
  void onClose() {
    // Clean up resources
    clearImage();
    super.onClose();
  }
}