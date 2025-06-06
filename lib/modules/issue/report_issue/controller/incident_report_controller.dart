import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/data/services/api_post_service.dart';
import 'package:security_guard/shared/widgets/snackbar_helper.dart';

class IncidentReportController extends GetxController {
  final descriptionController = TextEditingController();
  final characterCount = 0.obs;
  final maxCharacters = 500;
  final selectedPhotos = <XFile>[].obs;
  final currentPosition = Rxn<LatLng>();
  final mapController = MapController();
  final isLoading = false.obs;

  final _api = ApiPostServices();

  @override
  void onInit() {
    super.onInit();
    descriptionController.addListener(_updateCount);
    _determinePosition();
  }

  void _updateCount() {
    characterCount.value = descriptionController.text.length;
  }

  Future<void> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;
    }
    final pos = await Geolocator.getCurrentPosition();
    currentPosition.value = LatLng(pos.latitude, pos.longitude);
    if (currentPosition.value != null) {
      // ensure map move after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(currentPosition.value!, 15.0);
      });
    }
  }

  Future<void> pickImages() async {
    try {
      final imgs = await ImagePicker().pickMultiImage();
      if (imgs != null && imgs.isNotEmpty) selectedPhotos.addAll(imgs);
    } on PlatformException catch (e) {
      SnackbarHelper.error('Failed to pick images: $e');
    }
  }

  Future<void> submitReport() async {
    if (descriptionController.text.trim().isEmpty ||
        currentPosition.value == null) {
      SnackbarHelper.error('Please fill all required fields.');
      return;
    }
    isLoading.value = true;
    try {
      final resp = await _api.upsertIncidentReport(
        locationName: 'Alpha 1',
        siteId: '1',
        userId: '20240805',
        latitude: currentPosition.value!.latitude.toString(),
        longitude: currentPosition.value!.longitude.toString(),
        status: 'Active',
        companyId: '1',
        description: descriptionController.text.trim(),
        photoPaths: selectedPhotos.map((f) => f.path).toList(),
      );
      if (resp['status'] == true) {
        SnackbarHelper.success('Report submitted successfully!');
        Get.offAllNamed('/issues');
      } else {
        SnackbarHelper.error('Submission failed: ${resp['message'] ?? 'unknown'}');
      }
    } catch (e) {
      SnackbarHelper.error('Error submitting report: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}