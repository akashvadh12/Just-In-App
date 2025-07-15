import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/Compony/compony_location_controller.dart';

class CompanyLocationEditScreen extends StatefulWidget {
  final String companyID;
  final CompanyLocation? existingCompany;

  const CompanyLocationEditScreen({
    Key? key,
    required this.companyID,
    this.existingCompany,
  }) : super(key: key);

  @override
  State<CompanyLocationEditScreen> createState() =>
      _CompanyLocationEditScreenState();
}

class _CompanyLocationEditScreenState extends State<CompanyLocationEditScreen> {
  final CompanyLocationController controller =
      Get.find<CompanyLocationController>();
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _companyNameController;
  late TextEditingController _industryController;
  late TextEditingController _headquartersController;
  late TextEditingController _locationNameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _radiusController;
  late TextEditingController _websiteController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactNumberController;

  // Loading state for location
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    CompanyLocation? company =
        widget.existingCompany ??
        controller.getCompanyLocationById(widget.companyID);

    _companyNameController = TextEditingController(
      text: company?.companyName ?? '',
    );
    _industryController = TextEditingController(text: company?.industry ?? '');
    _headquartersController = TextEditingController(
      text: company?.headquarters ?? '',
    );
    _locationNameController = TextEditingController(
      text: company?.locationName ?? '',
    );
    _latitudeController = TextEditingController(text: company?.latitude ?? '');
    _longitudeController = TextEditingController(
      text: company?.longitude ?? '',
    );
    _radiusController = TextEditingController(text: company?.radius ?? '');
    _websiteController = TextEditingController();
    _contactEmailController = TextEditingController();
    _contactNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _industryController.dispose();
    _headquartersController.dispose();
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    _websiteController.dispose();
    _contactEmailController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  // Location permission and service methods
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog(
        'Location Services Disabled',
        'Please enable location services to use this feature.',
        [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      );
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDialog(
          'Location Permission Denied',
          'Location permissions are required to get your current location.',
          [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationDialog(
        'Location Permission Permanently Denied',
        'Location permissions are permanently denied. Please enable them in app settings.',
        [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppColors.greyColor)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Geolocator.openAppSettings();
            },
            child: Text('Settings', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    if (!await _checkLocationPermission()) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });

      Get.snackbar(
        'Success',
        'Current location updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      String errorMessage = 'Failed to get current location';
      if (e is LocationServiceDisabledException) {
        errorMessage = 'Location services are disabled';
      } else if (e is PermissionDeniedException) {
        errorMessage = 'Location permission denied';
      } 

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showLocationDialog(String title, String message, List<Widget> actions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: AppTextStyles.subtitle),
          content: Text(message, style: AppTextStyles.body),
          actions: actions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Company Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Information Card
              _buildSectionCard(
                title: 'Company Information',
                icon: Icons.business,
                children: [
                  _buildCompanyNameField(),
                  const SizedBox(height: 16),
                  _buildIndustryField(),
                  const SizedBox(height: 16),
                  _buildHeadquartersField(),
                ],
              ),
              const SizedBox(height: 24),

              // Location Information Card
              _buildSectionCard(
                title: 'Location Information',
                icon: Icons.location_on,
                children: [
                  _buildLocationNameField(),
                  const SizedBox(height: 16),
                  _buildLocationCoordinatesSection(),
                  const SizedBox(height: 16),
                  _buildRadiusField(),
                ],
              ),
              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: AppColors.whiteColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.whiteColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCoordinatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Location Button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            icon: _isLoadingLocation
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.whiteColor,
                      ),
                    ),
                  )
                : Icon(Icons.my_location, size: 18),
            label: Text(
              _isLoadingLocation ? 'Getting Location...' : 'Use Current Location',
              style: AppTextStyles.body.copyWith(
                color: AppColors.whiteColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.whiteColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Coordinates Input Row
        Row(
          children: [
            Expanded(child: _buildLatitudeField()),
            const SizedBox(width: 16),
            Expanded(child: _buildLongitudeField()),
          ],
        ),
        const SizedBox(height: 8),

        // Coordinates Info
        if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coordinates: ${_latitudeController.text}, ${_longitudeController.text}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompanyNameField() {
    return TextFormField(
      controller: _companyNameController,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: 'Company Name *',
        labelStyle: AppTextStyles.hint,
        hintText: 'Enter company name',
        hintStyle: AppTextStyles.hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.business, color: AppColors.greyColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Company name is required';
        }
        return null;
      },
    );
  }

  Widget _buildIndustryField() {
    return TextFormField(
      controller: _industryController,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: 'Industry *',
        labelStyle: AppTextStyles.hint,
        hintText: 'Enter industry type',
        hintStyle: AppTextStyles.hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.category, color: AppColors.greyColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Industry is required';
        }
        return null;
      },
    );
  }

  Widget _buildHeadquartersField() {
    return TextFormField(
      controller: _headquartersController,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: 'Headquarters *',
        labelStyle: AppTextStyles.hint,
        hintText: 'Enter headquarters location',
        hintStyle: AppTextStyles.hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.location_city, color: AppColors.greyColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Headquarters is required';
        }
        return null;
      },
    );
  }

  Widget _buildLocationNameField() {
    return TextFormField(
      controller: _locationNameController,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: 'Location Name *',
        labelStyle: AppTextStyles.hint,
        hintText: 'Enter location name',
        hintStyle: AppTextStyles.hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.place, color: AppColors.greyColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Location name is required';
        }
        return null;
      },
    );
  }

  Widget _buildLatitudeField() {
    return TextFormField(
      controller: _latitudeController,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: 'Latitude',
        labelStyle: AppTextStyles.hint,
        hintText: 'Enter latitude',
        hintStyle: AppTextStyles.hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.map, color: AppColors.greyColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final lat = double.tryParse(value);
          if (lat == null || lat < -90 || lat > 90) {
            return 'Invalid latitude';
          }
        }
        return null;
      },
    );
  }

  Widget _buildLongitudeField() {
    return TextFormField(
      controller: _longitudeController,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: 'Longitude',
        labelStyle: AppTextStyles.hint,
        hintText: 'Enter longitude',
        hintStyle: AppTextStyles.hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.map, color: AppColors.greyColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final lng = double.tryParse(value);
          if (lng == null || lng < -180 || lng > 180) {
            return 'Invalid longitude';
          }
        }
        return null;
      },
    );
  }

  Widget _buildRadiusField() {
    return TextFormField(
      controller: _radiusController,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: 'Radius (meters)',
        labelStyle: AppTextStyles.hint,
        hintText: 'Enter radius in meters',
        hintStyle: AppTextStyles.hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.greyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(
          Icons.radio_button_checked,
          color: AppColors.greyColor,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final radius = double.tryParse(value);
          if (radius == null || radius < 0) {
            return 'Please enter a valid radius';
          }
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.greyColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.greyColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => ElevatedButton(
              onPressed: (controller.isSubmitting.value || _isLoadingLocation) ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  controller.isSubmitting.value
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.whiteColor,
                          ),
                        ),
                      )
                      : Text(
                        'Update Company',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.whiteColor,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source', style: AppTextStyles.subtitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('Camera', style: AppTextStyles.body),
                onTap: () {
                  Get.back();
                  controller.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('Gallery', style: AppTextStyles.body),
                onTap: () {
                  Get.back();
                  controller.pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await controller.updateCompanyLocation(
      companyID: widget.companyID,
      companyName: _companyNameController.text.trim(),
      industry: _industryController.text.trim(),
      headquarters: _headquartersController.text.trim(),
      locationName: _locationNameController.text.trim(),
      latitude:
          _latitudeController.text.trim().isEmpty
              ? null
              : _latitudeController.text.trim(),
      longitude:
          _longitudeController.text.trim().isEmpty
              ? null
              : _longitudeController.text.trim(),
      radius:
          _radiusController.text.trim().isEmpty
              ? null
              : _radiusController.text.trim(),
    );

    if (success) {

    Get.back(canPop: true);

    }
  }
}