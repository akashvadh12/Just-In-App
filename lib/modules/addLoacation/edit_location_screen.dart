import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/addLoacation/location_controller.dart';

class EditLocationScreen extends StatefulWidget {
  final Location location;
  
  const EditLocationScreen({Key? key, required this.location}) : super(key: key);

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final LocationController controller = Get.find<LocationController>();
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _locationNameController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _radiusController;
  
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _locationNameController = TextEditingController(text: widget.location.locationName);
    _latitudeController = TextEditingController(text: widget.location.latitude);
    _longitudeController = TextEditingController(text: widget.location.longitude);
    _radiusController = TextEditingController(text: widget.location.radius);
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.delete_outline),
        //     onPressed: () => _showDeleteDialog(),
        //     tooltip: 'Delete Location',
        //   ),
        // ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card with current location info
              _buildHeaderCard(),
              const SizedBox(height: 20),

              // Location Details Card
              _buildLocationDetailsCard(),
              const SizedBox(height: 20),

              // Coordinates Card
              _buildCoordinatesCard(),
              const SizedBox(height: 20),

              // Photo Card
              _buildPhotoCard(),
              const SizedBox(height: 30),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_location_alt,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update location details',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current: ${widget.location.locationName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'ID: ${widget.location.locationId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Location Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationNameController,
            decoration: InputDecoration(
              labelText: 'Location Name',
              hintText: 'Enter location name',
              prefixIcon: Icon(Icons.place, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter location name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _radiusController,
            decoration: InputDecoration(
              labelText: 'Monitoring Radius (meters)',
              hintText: 'Enter radius in meters',
              prefixIcon: Icon(Icons.radio_button_checked, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS Coordinates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildCurrentLocationButton(),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Changing coordinates will update the location boundary',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    hintText: '0.0000',
                    prefixIcon: Icon(Icons.explore, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    hintText: '0.0000',
                    prefixIcon: Icon(Icons.explore, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isGettingLocation ? null : _getCurrentLocation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isGettingLocation)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  Icon(
                    Icons.gps_fixed,
                    size: 14,
                    color: AppColors.primary,
                  ),
                const SizedBox(width: 6),
                Text(
                  _isGettingLocation ? 'Getting...' : 'Current',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.camera_alt, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update Location Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (controller.selectedImage.value != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'New',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Optional: Upload a new photo to replace the current one',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Photo area
            GestureDetector(
              onTap: () => _showImagePicker(context),
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: controller.selectedImage.value != null
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: controller.selectedImage.value != null
                      ? Stack(
                          children: [
                            Image.file(
                              controller.selectedImage.value!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: GestureDetector(
                                  onTap: controller.clearImage,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey[50],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Update Photo',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Tap to select new photo',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActionButtons() {
    return Obx(() {
      return Column(
        children: [
          // Update Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: controller.isSubmitting.value ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: controller.isSubmitting.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Updating Location...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Update Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Reset Button
          OutlinedButton(
            onPressed: controller.isSubmitting.value ? null : _resetForm,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Reset to Original',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Services Disabled',
          'Please enable location services to get current location',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: Icon(Icons.location_off, color: Colors.white),
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Location Permission Denied',
            'Location permissions are required to get current location',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            icon: Icon(Icons.location_off, color: Colors.white),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Location Permission Denied',
          'Location permissions are permanently denied. Please enable them in settings.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: Icon(Icons.location_off, color: Colors.white),
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);

      Get.snackbar(
        'Location Updated',
        'Current location coordinates have been updated',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: Icon(Icons.gps_fixed, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get current location: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Update Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImagePickerOption(
                              icon: Icons.camera_alt,
                              label: 'Camera',
                              onTap: () {
                                Navigator.pop(context);
                                controller.pickImage(ImageSource.camera);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildImagePickerOption(
                              icon: Icons.photo_library,
                              label: 'Gallery',
                              onTap: () {
                                Navigator.pop(context);
                                controller.pickImage(ImageSource.gallery);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _locationNameController.text = widget.location.locationName;
    _latitudeController.text = widget.location.latitude;
    _longitudeController.text = widget.location.longitude;
    _radiusController.text = widget.location.radius;
    controller.clearImage();
    
    Get.snackbar(
      'Form Reset',
      'All fields have been reset to original values',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      icon: Icon(Icons.refresh, color: Colors.white),
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text('Delete Location'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.location.locationName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _deleteLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation() async {
    // You'll need to implement this method in your LocationController
    final success = await controller.deleteLocation(widget.location.locationId);
    if (success) {
      Get.back(); // Go back to previous screen
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final success = await controller.updateLocation(
        locationId: widget.location.locationId,
        locationName: _locationNameController.text.trim(),
        latitude: _latitudeController.text.trim().isNotEmpty ? _latitudeController.text.trim() : null,
        longitude: _longitudeController.text.trim().isNotEmpty ? _longitudeController.text.trim() : null,
        radius: _radiusController.text.trim().isNotEmpty ? _radiusController.text.trim() : null,
        photo: controller.selectedImage.value,
      );

      if (success) {
        controller.clearImage();
        
       Get.back(closeOverlays: true);
      }
    }
  }
}