import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:security_guard/data/services/api_post_service.dart';
import 'dart:io';
import 'dart:convert';

import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';

class CompanyLocation {
  final String companyID;
  final String companyName;
  final String industry;
  final String headquarters;
  final String latitude;
  final String longitude;
  final String locationName;
  final bool status;
  final String radius;

  CompanyLocation({
    required this.companyID,
    required this.companyName,
    required this.industry,
    required this.headquarters,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.status,
    required this.radius,
  });

  factory CompanyLocation.fromJson(Map<String, dynamic> json) {
    return CompanyLocation(
      companyID: json['companyID']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      industry: json['industry']?.toString() ?? '',
      headquarters: json['headquarters']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      locationName: json['locationName']?.toString() ?? '',
      status: json['status'] ?? false,
      radius: json['radius']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyID': companyID,
      'companyName': companyName,
      'industry': industry,
      'headquarters': headquarters,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'status': status,
      'radius': radius,
    };
  }

  // Copy with method for easy updates
  CompanyLocation copyWith({
    String? companyID,
    String? companyName,
    String? industry,
    String? headquarters,
    String? latitude,
    String? longitude,
    String? locationName,
    bool? status,
    String? radius,
  }) {
    return CompanyLocation(
      companyID: companyID ?? this.companyID,
      companyName: companyName ?? this.companyName,
      industry: industry ?? this.industry,
      headquarters: headquarters ?? this.headquarters,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
      radius: radius ?? this.radius,
    );
  }
}

// ========================= CONTROLLER =========================

class CompanyLocationController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final ApiPostServices _apiPostService = ApiPostServices();
  final String userId = Get.find<ProfileController>().userModel.value!.userId;

  // Observable variables
  RxList<CompanyLocation> companyLocations = <CompanyLocation>[].obs;
  RxList<CompanyLocation> filteredCompanyLocations = <CompanyLocation>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSubmitting = false.obs;
  RxBool isDeleting = false.obs;
  Rx<File?> selectedImage = Rx<File?>(null);
  RxString searchQuery = ''.obs;
  RxString selectedIndustry = ''.obs;
  RxString selectedHeadquarters = ''.obs;
  RxBool showActiveOnly = false.obs;

  // API URLs
  final String getAllCompaniesUrl =
      'https://justin.solarvision-cairo.com/api/CompanyConfig/GetCompanyLoc';
  final String baseUrl = 'https://justin.solarvision-cairo.com/api/Loaction';

  @override
  void onInit() {
    super.onInit();
    fetchCompanyLocations();

    // Listen to search and filter changes
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedIndustry, (_) => _applyFilters());
    ever(selectedHeadquarters, (_) => _applyFilters());
    ever(showActiveOnly, (_) => _applyFilters());
  }

  // ========================= FETCH OPERATIONS =========================

  /// Fetch all company locations from the server
  Future<void> fetchCompanyLocations() async {
    try {
      isLoading(true);

      final url = Uri.parse(getAllCompaniesUrl);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        companyLocations.value =
            data.map((json) => CompanyLocation.fromJson(json)).toList();
        _applyFilters(); // Apply current filters to the new data

      } else {
        _showErrorMessage(
          'Failed to fetch company locations: ${response.body}',
        );
      }
    } catch (e) {
      _showErrorMessage('Failed to fetch company locations: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Refresh company locations
  Future<void> refreshCompanyLocations() async {
    await fetchCompanyLocations();
  }

  // ========================= CREATE OPERATIONS =========================

  /// Add new company location
  Future<bool> addCompanyLocation({
    required String companyName,
    required String industry,
    required String headquarters,
    required String locationName,
    required String latitude,
    required String longitude,
    required String radius,
    File? photo,
  }) async {
    if (!_validateRequiredFields(
      companyName,
      industry,
      headquarters,
      locationName,
      latitude,
      longitude,
      radius,
    )) {
      return false;
    }

    try {
      isSubmitting(true);

      final url = Uri.parse('$baseUrl/add');
      final request =
          http.MultipartRequest('POST', url)
            ..fields['Company_Name'] = companyName
            ..fields['Industry'] = industry
            ..fields['Headquarters'] = headquarters
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
        _showSuccessMessage(
          respJson['message'] ?? 'Company location added successfully',
        );
        await fetchCompanyLocations(); // Refresh the list
        clearImage(); // Clear selected image after successful submission
        return true;
      } else {
        _showErrorMessage('Failed to add company location: ${response.body}');
        return false;
      }
    } catch (e) {
      _showErrorMessage('Failed to add company location: $e');
      return false;
    } finally {
      isSubmitting(false);
    }
  }

  // ========================= UPDATE OPERATIONS =========================

  /// Update company location
  Future<bool> updateCompanyLocation({
    required String companyID,
    required String companyName,
    required String industry,
    required String headquarters,
    required String locationName,
    String? latitude,
    String? longitude,
    String? radius,
    File? photo,
    bool? status,
    String? userId,
  }) async {
    if (companyID.isEmpty ||
        companyName.isEmpty ||
        industry.isEmpty ||
        headquarters.isEmpty ||
        locationName.isEmpty) {
      _showErrorMessage('All required fields must be filled');
      return false;
    }

    try {
      isSubmitting(true);

      // Get existing company data to fill missing fields
      CompanyLocation? existingCompany = getCompanyLocationById(companyID);

      // Use provided values or fallback to existing values or defaults
      final String finalLatitude =
          latitude ?? existingCompany?.latitude ?? '0.0';
      final String finalLongitude =
          longitude ?? existingCompany?.longitude ?? '0.0';
      final String finalRadius = radius ?? existingCompany?.radius ?? '0';
      final bool finalStatus = status ?? existingCompany?.status ?? true;
      final String userId =
          Get.find<ProfileController>().userModel.value!.userId;

      // If no photo is provided, use the API service method for basic update
      if (photo == null) {
        final response = await _apiPostService.updateCompanyAPI(
          companyID: companyID,
          companyName: companyName,
          industry: industry,
          headquarters: headquarters,
          latitude: finalLatitude,
          longitude: finalLongitude,
          locationName: locationName,
          radius: finalRadius,

          status: finalStatus,
        );

        if (response != null && response['success'] == true) {
          _showSuccessMessage(
            response['message'] ?? 'Company location updated successfully',
          );
          await fetchCompanyLocations(); // Refresh the list
          return true;
        } else {
          _showSuccessMessage(
            response?['message'] ?? 'Company location updated successfully',
          );
          // _showErrorMessage(response?['message'] ?? 'Failed to update company location');
          return false;
        }
      } else {
        // If photo is provided, use multipart request to handle photo upload
        final url = Uri.parse('$baseUrl/update');
        final request =
            http.MultipartRequest('PUT', url)
              ..fields['Company_ID'] = companyID
              ..fields['Company_Name'] = companyName
              ..fields['Industry'] = industry
              ..fields['Headquarters'] = headquarters
              ..fields['Location_Name'] = locationName
              ..fields['Latitude'] = finalLatitude
              ..fields['Longitude'] = finalLongitude
              ..fields['Radius'] = finalRadius
              ..fields['UserId'] = userId
              ..fields['Status'] = finalStatus.toString();

        // Add photo to the request
        request.files.add(
          await http.MultipartFile.fromPath('Photos', photo.path),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final respJson = json.decode(response.body);
          _showSuccessMessage(
            respJson['message'] ?? 'Company location updated successfully',
          );
          await fetchCompanyLocations(); // Refresh the list
          clearImage(); // Clear selected image after successful submission
          return true;
        } else {
          _showErrorMessage(
            'Failed to update company location: ${response.body}',
          );
          return false;
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to update company location: $e');
      return false;
    } finally {
      isSubmitting(false);
    }
  }

  /// Toggle company status (active/inactive)
  Future<bool> toggleCompanyStatus(String companyID) async {
    CompanyLocation? company = getCompanyLocationById(companyID);
    if (company == null) {
      _showErrorMessage('Company not found');
      return false;
    }

    return await updateCompanyLocation(
      companyID: companyID,
      companyName: company.companyName,
      industry: company.industry,
      headquarters: company.headquarters,
      locationName: company.locationName,
      latitude: company.latitude,
      longitude: company.longitude,
      radius: company.radius,
      status: !company.status,
    );
  }

  // ========================= DELETE OPERATIONS =========================

  /// Delete company location
  Future<bool> deleteCompanyLocation(String companyID) async {
    if (companyID.isEmpty) {
      _showErrorMessage('Company ID is required');
      return false;
    }

    try {
      isDeleting(true);

      final url = Uri.parse('$baseUrl/delete/$companyID');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final respJson = json.decode(response.body);
        _showSuccessMessage(
          respJson['message'] ?? 'Company location deleted successfully',
        );
        await fetchCompanyLocations(); // Refresh the list
        return true;
      } else {
        _showErrorMessage(
          'Failed to delete company location: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      _showErrorMessage('Failed to delete company location: $e');
      return false;
    } finally {
      isDeleting(false);
    }
  }

  /// Delete multiple company locations
  Future<bool> deleteMultipleCompanyLocations(List<String> companyIDs) async {
    if (companyIDs.isEmpty) {
      _showErrorMessage('No companies selected for deletion');
      return false;
    }

    try {
      isDeleting(true);
      int successCount = 0;
      int failureCount = 0;

      for (String companyID in companyIDs) {
        final url = Uri.parse('$baseUrl/delete/$companyID');
        final response = await http.delete(url);

        if (response.statusCode == 200) {
          successCount++;
        } else {
          failureCount++;
        }
      }

      if (successCount > 0) {
        _showSuccessMessage('$successCount companies deleted successfully');
        await fetchCompanyLocations(); // Refresh the list
      }

      if (failureCount > 0) {
        _showErrorMessage('Failed to delete $failureCount companies');
      }

      return failureCount == 0;
    } catch (e) {
      _showErrorMessage('Failed to delete companies: $e');
      return false;
    } finally {
      isDeleting(false);
    }
  }

  // ========================= IMAGE OPERATIONS =========================

  /// Pick image from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress image to reduce file size
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  /// Clear selected image
  void clearImage() {
    selectedImage.value = null;
  }

  // ========================= SEARCH AND FILTER OPERATIONS =========================

  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Set industry filter
  void setIndustryFilter(String industry) {
    selectedIndustry.value = industry;
  }

  /// Set headquarters filter
  void setHeadquartersFilter(String headquarters) {
    selectedHeadquarters.value = headquarters;
  }

  /// Toggle active only filter
  void toggleActiveOnlyFilter() {
    showActiveOnly.value = !showActiveOnly.value;
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    selectedIndustry.value = '';
    selectedHeadquarters.value = '';
    showActiveOnly.value = false;
  }

  /// Apply filters to company locations
  void _applyFilters() {
    List<CompanyLocation> filtered = companyLocations.toList();

    // Apply search query filter
    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered.where((company) {
            final query = searchQuery.value.toLowerCase();
            return company.companyName.toLowerCase().contains(query) ||
                company.locationName.toLowerCase().contains(query) ||
                company.industry.toLowerCase().contains(query) ||
                company.headquarters.toLowerCase().contains(query);
          }).toList();
    }

    // Apply industry filter
    if (selectedIndustry.value.isNotEmpty) {
      filtered =
          filtered
              .where(
                (company) => company.industry.toLowerCase().contains(
                  selectedIndustry.value.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply headquarters filter
    if (selectedHeadquarters.value.isNotEmpty) {
      filtered =
          filtered
              .where(
                (company) => company.headquarters.toLowerCase().contains(
                  selectedHeadquarters.value.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply active only filter
    if (showActiveOnly.value) {
      filtered = filtered.where((company) => company.status).toList();
    }

    filteredCompanyLocations.value = filtered;
  }

  // ========================= GETTER METHODS =========================

  /// Get company location by ID
  CompanyLocation? getCompanyLocationById(String companyID) {
    try {
      return companyLocations.firstWhere(
        (location) => location.companyID == companyID,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if company location exists
  bool companyLocationExists(String companyID) {
    return companyLocations.any((location) => location.companyID == companyID);
  }

  /// Get companies by industry
  List<CompanyLocation> getCompaniesByIndustry(String industry) {
    return companyLocations
        .where(
          (location) =>
              location.industry.toLowerCase().contains(industry.toLowerCase()),
        )
        .toList();
  }

  /// Get companies by headquarters
  List<CompanyLocation> getCompaniesByHeadquarters(String headquarters) {
    return companyLocations
        .where(
          (location) => location.headquarters.toLowerCase().contains(
            headquarters.toLowerCase(),
          ),
        )
        .toList();
  }

  /// Get active companies
  List<CompanyLocation> getActiveCompanies() {
    return companyLocations.where((location) => location.status).toList();
  }

  /// Get inactive companies
  List<CompanyLocation> getInactiveCompanies() {
    return companyLocations.where((location) => !location.status).toList();
  }

  /// Get unique industries
  List<String> getUniqueIndustries() {
    return companyLocations
        .map((location) => location.industry)
        .where((industry) => industry.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get unique headquarters
  List<String> getUniqueHeadquarters() {
    return companyLocations
        .map((location) => location.headquarters)
        .where((headquarters) => headquarters.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get companies count by status
  Map<String, int> getCompanyCountByStatus() {
    final active = getActiveCompanies().length;
    final inactive = getInactiveCompanies().length;
    return {'active': active, 'inactive': inactive, 'total': active + inactive};
  }

  /// Get companies count by industry
  Map<String, int> getCompanyCountByIndustry() {
    final Map<String, int> industryCount = {};
    for (final company in companyLocations) {
      if (company.industry.isNotEmpty) {
        industryCount[company.industry] =
            (industryCount[company.industry] ?? 0) + 1;
      }
    }
    return industryCount;
  }

  // ========================= UTILITY METHODS =========================

  /// Validate required fields
  bool _validateRequiredFields(
    String companyName,
    String industry,
    String headquarters,
    String locationName,
    String latitude,
    String longitude,
    String radius,
  ) {
    if (companyName.isEmpty ||
        industry.isEmpty ||
        headquarters.isEmpty ||
        locationName.isEmpty ||
        latitude.isEmpty ||
        longitude.isEmpty ||
        radius.isEmpty) {
      _showErrorMessage('Please fill in all required fields');
      return false;
    }
    return true;
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show loading dialog
  void showLoadingDialog() {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  void hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Sort companies by name
  void sortCompaniesByName({bool ascending = true}) {
    companyLocations.sort((a, b) {
      return ascending
          ? a.companyName.compareTo(b.companyName)
          : b.companyName.compareTo(a.companyName);
    });
    _applyFilters();
  }

  /// Sort companies by industry
  void sortCompaniesByIndustry({bool ascending = true}) {
    companyLocations.sort((a, b) {
      return ascending
          ? a.industry.compareTo(b.industry)
          : b.industry.compareTo(a.industry);
    });
    _applyFilters();
  }

  /// Sort companies by headquarters
  void sortCompaniesByHeadquarters({bool ascending = true}) {
    companyLocations.sort((a, b) {
      return ascending
          ? a.headquarters.compareTo(b.headquarters)
          : b.headquarters.compareTo(a.headquarters);
    });
    _applyFilters();
  }

  /// Sort companies by status
  void sortCompaniesByStatus({bool activeFirst = true}) {
    companyLocations.sort((a, b) {
      return activeFirst
          ? b.status.toString().compareTo(a.status.toString())
          : a.status.toString().compareTo(b.status.toString());
    });
    _applyFilters();
  }

  // ========================= CLEANUP =========================

  @override
  void onClose() {
    // Clean up resources
    clearImage();
    super.onClose();
  }
}
