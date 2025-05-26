import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/issue/issue_list/issue_view/issue_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({Key? key}) : super(key: key);

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final int _maxCharacters = 500;
  final RxInt _characterCount = 0.obs;
  final RxList<XFile> _selectedPhotos = <XFile>[].obs;
  final Rxn<LatLng> _currentPosition = Rxn<LatLng>();
  final MapController _mapController = MapController();
  final RxBool _isLoading = false.obs;
  final RxBool _isLocationLoading = true.obs;

  Future<String?> getAuthTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateCharacterCount);
    _getCurrentLocation();
  }

  void _updateCharacterCount() {
    _characterCount.value = _descriptionController.text.length;
  }

  Future<void> _getCurrentLocation() async {
    _isLocationLoading.value = true;
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isLocationLoading.value = false;
      Get.snackbar(
        'Location Service Disabled',
        'Please enable location services to report incidents',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        _isLocationLoading.value = false;
        Get.snackbar(
          'Location Permission Denied',
          'Location permission is required to report incidents',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPosition = LatLng(position.latitude, position.longitude);
      _currentPosition.value = newPosition;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentPosition.value != null) {
          _mapController.move(_currentPosition.value!, 15.0);
        }
      });
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get current location: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLocationLoading.value = false;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        _selectedPhotos.addAll(images);
      }
    } on PlatformException catch (e) {
      Get.snackbar(
        'Image Picker Error',
        'Failed to pick images: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _removePhoto(XFile photo) {
    _selectedPhotos.remove(photo);
  }

  bool _validateForm() {
    // Check location
    if (_currentPosition.value == null) {
      Get.snackbar(
        'Missing Location',
        'Please allow location access or wait for it to load',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    // Check description
    if (_descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Description',
        'Please provide a brief description of the incident',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    // Check photos
    if (_selectedPhotos.isEmpty) {
      Get.snackbar(
        'Missing Incident Photo(s)',
        'Please add at least one photo for the incident',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitReport() async {
    if (!_validateForm()) return;

    _isLoading.value = true;

    try {
      // Retrieve the auth token first
      final token = await getAuthTokenFromPrefs();
      if (token == null || token.isEmpty) {
        Get.snackbar(
          'Authentication Error',
          'You must be logged in to submit report',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final uri = Uri.parse(
        "https://qrapp.solarvision-cairo.com/api/Admin/UpsertIncidentReport",
      );

      final headers = {
        'Authorization': 'Bearer $token',
      };

      // Send multipart request with photos
      final request = http.MultipartRequest("POST", uri);
      request.headers.addAll(headers);

      request.fields['LocationName'] = 'Alpha 1';
      request.fields['SiteId'] = '1';
      request.fields['UserId'] = '20240805';
      request.fields['Latitude'] = _currentPosition.value!.latitude.toString();
      request.fields['Longitude'] = _currentPosition.value!.longitude.toString();
      request.fields['Status'] = 'Active';
      request.fields['CompanyId'] = '1';
      request.fields['Description'] = _descriptionController.text.trim();

      // Add first photo (you can modify this to handle multiple photos)
      final photo = _selectedPhotos.first;
      final mimeType = lookupMimeType(photo.path) ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);
      final file = await http.MultipartFile.fromPath(
        'Photo',
        photo.path,
        filename: path.basename(photo.path),
        contentType: mediaType,
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _clearForm();
        Get.snackbar(
          'Success',
          'Report submitted successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.off(() => const IssuesScreen());
      } else {
        Get.snackbar(
          'Submission Failed',
          'Failed to submit report: ${response.reasonPhrase}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error submitting report: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _clearForm() {
    _descriptionController.clear();
    _selectedPhotos.clear();
    _characterCount.value = 0;
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateCharacterCount);
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
        title: const Text('Report Incident'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Section
            Row(
              children: [
                const Text('Current Location', style: AppTextStyles.heading),
                const SizedBox(width: 8),
                const Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
              ),
              child: Obx(() => _isLocationLoading.value
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Getting your location...'),
                        ],
                      ),
                    )
                  : _currentPosition.value == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('Location not available'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _getCurrentLocation,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition.value!,
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentPosition.value!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )),
            ),
            const SizedBox(height: 24),

            // Photos Section
            Row(
              children: [
                const Text('Incident Photos', style: AppTextStyles.heading),
                const SizedBox(width: 8),
                const Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: Obx(() => ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.greyColor.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: AppColors.greyColor),
                              const SizedBox(height: 2),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ..._selectedPhotos.map(
                        (img) => Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(img.path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removePhoto(img),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            ),
            const SizedBox(height: 24),

            // Description Section
            Row(
              children: [
                const Text('Incident Description', style: AppTextStyles.heading),
                const SizedBox(width: 8),
                const Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 8,
                maxLength: _maxCharacters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_maxCharacters),
                ],
                decoration: const InputDecoration(
                  hintText: 'Describe the incident in detail...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                  counterText: '',
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Obx(() => Text(
                      '${_characterCount.value}/$_maxCharacters',
                      style: TextStyle(color: AppColors.greyColor, fontSize: 12),
                    )),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              '* Required fields must be filled',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Obx(() => ElevatedButton(
                    onPressed: _isLoading.value ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  )),
            ),
            const SizedBox(height: 12),

            // View Issues Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Get.to(() => const IssuesScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: AppColors.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Reported Issues',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}