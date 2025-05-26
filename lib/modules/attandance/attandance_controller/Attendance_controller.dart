import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class GuardAttendanceController extends GetxController {
  var capturedImage = Rx<File?>(null);
  var currentPosition = Rx<Position?>(null);
  var isLocationVerified = false.obs;
  var isClockedIn = false.obs;
  var lastAction = "No recent activity".obs;
  var clockInTime;
  var clockOutTime;
  var isLoadingLocation = false.obs;

  Future<void> capturePhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );

    if (pickedFile != null) {
      capturedImage.value = File(pickedFile.path);
      Get.snackbar(
        "Photo Captured",
        "Verification photo taken successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: Icon(Icons.check_circle, color: Colors.white),
        duration: Duration(seconds: 2),
      );
    }
  }

  Future<void> getCurrentLocation() async {
    isLoadingLocation.value = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          "Location Service Disabled",
          "Please enable location services",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: Icon(Icons.location_off, color: Colors.white),
        );
        await Geolocator.openLocationSettings();
        isLoadingLocation.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          Get.snackbar(
            "Permission Denied",
            "Location permission is required for attendance",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: Icon(Icons.error, color: Colors.white),
          );
          isLoadingLocation.value = false;
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = position;
      isLocationVerified.value = true;
      isLoadingLocation.value = false;

      Get.snackbar(
        "Location Verified",
        "GPS location has been successfully verified",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: Icon(Icons.location_on, color: Colors.white),
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      isLocationVerified.value = false;
      isLoadingLocation.value = false;

      Get.snackbar(
        "Location Error",
        "Failed to get location. Please try again",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
      );
    }
  }

  void clockIn() {
    isClockedIn.value = true;
    clockInTime = DateTime.now();
    lastAction.value = "Clocked IN at ${formatTime(clockInTime!)}";

    Get.snackbar(
      "Clock In Successful",
      "Welcome! Your shift has started",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: Icon(Icons.check_circle, color: Colors.white),
      duration: Duration(seconds: 3),
    );
  }

  void clockOut() {
    isClockedIn.value = false;
    clockOutTime = DateTime.now();
    lastAction.value = "Clocked OUT at ${formatTime(clockOutTime!)}";

    Get.snackbar(
      "Clock Out Successful",
      "Have a great day! Your shift has ended",
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: Icon(Icons.exit_to_app, color: Colors.white),
      duration: Duration(seconds: 3),
    );
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
}