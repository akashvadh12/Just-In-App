import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileController extends GetxController {
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userId = ''.obs;
  final RxString profileImage = ''.obs;
  final RxBool isLoading = false.obs;

  static const String _baseUrl = "https://official.solarvision-cairo.com/api/";
  static const Duration _timeout = Duration(seconds: 30);

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  // ==================== SHARED PREFERENCES METHODS ====================

  Future<UserModel?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null && userDataString.isNotEmpty) {
        final userData = UserModel.fromJson(jsonDecode(userDataString));
        // Ensure userId is also stored separately for consistency
        if (userData.userId.isNotEmpty) {
          await prefs.setString('user_id', userData.userId);
        }
        return userData;
      }
      return null;
    } catch (e) {
      print('Error retrieving user model: $e');
      return null;
    }
  }

  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First try to get from user_id key
      String? storedUserId = prefs.getString('user_id');
      
      // If not found, try to get from user_data
      if (storedUserId == null || storedUserId.isEmpty) {
        final userData = await getUserData();
        if (userData != null && userData.userId.isNotEmpty) {
          storedUserId = userData.userId;
          // Store it for future use
          await prefs.setString('user_id', storedUserId);
        }
      }
      
      print('Retrieved user ID from SharedPreferences: $storedUserId');
      return storedUserId?.isNotEmpty == true ? storedUserId : null;
    } catch (e) {
      print('Error retrieving user ID: $e');
      return null;
    }
  }

  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      return token?.isNotEmpty == true ? token : null;
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  Future<void> updateUserData({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = await getUserData();

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          name: name ?? currentUser.name,
          email: email ?? currentUser.email,
          phone: phone ?? currentUser.phone,
          photoPath: profileImage ?? currentUser.photoPath,
          userId: userId ?? currentUser.userId,
        );

        await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));
        
        // Update individual fields
        if (name != null) await prefs.setString('user_name', name);
        if (email != null) await prefs.setString('user_email', email);
        if (phone != null) await prefs.setString('user_phone', phone);
        if (profileImage != null) await prefs.setString('profile_image', profileImage);
        if (userId != null) await prefs.setString('user_id', userId);
      } else if (userId != null) {
        // If no current user data but we have a userId, store it
        await prefs.setString('user_id', userId);
      }
    } catch (e) {
      print('Error updating user data: $e');
      throw Exception('Failed to update user data');
    }
  }

  // ==================== API METHODS ====================

  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': '*/*',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>?> _handleResponse(http.Response response) async {
    try {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          // Add status true if not present for successful responses
          if (!responseData.containsKey('status')) {
            responseData['status'] = true;
          }
          return responseData;
        }
        return {'status': true, 'message': 'Success'};
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        
        // Try to parse error response
        Map<String, dynamic> errorResponse = {
          'status': false,
          'message': 'Server error: ${response.statusCode}',
          'error_code': response.statusCode,
        };
        
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body) as Map<String, dynamic>;
            errorResponse['message'] = errorData['message'] ?? 
                                     errorData['error'] ?? 
                                     'Server error: ${response.statusCode}';
          }
        } catch (e) {
          print('Could not parse error response: $e');
        }
        
        return errorResponse;
      }
    } catch (e) {
      print('Error parsing response: $e');
      return {
        'status': false,
        'message': 'Failed to parse server response',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>?> getProfileAPI(String userId) async {
    try {
      final url = Uri.parse('${_baseUrl}profile?UserId=$userId');
      final token = await getAuthToken();

      print('Fetching profile for userId: $userId');
      final response = await http
          .get(url, headers: _getHeaders(token: token))
          .timeout(_timeout);

      return await _handleResponse(response);
    } catch (e) {
      print('Error getting profile: $e');
      return {
        'status': false,
        'message': 'Failed to fetch profile',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>?> updateProfileAPI({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final url = Uri.parse('${_baseUrl}profile/update');
      final token = await getAuthToken();

      final body = {
        'userId': userId,
        'name': name,
        'email': email,
        'mobile_No': phone,
      };

      print('Updating profile for userId: $userId');
      print('Request body: ${jsonEncode(body)}');
      
      final response = await http
          .put(url, headers: _getHeaders(token: token), body: jsonEncode(body))
          .timeout(_timeout);

      print('Update profile response: ${response.statusCode} - ${response.body}');
      return await _handleResponse(response);
    } catch (e) {
      print('Error updating profile: $e');
      return {
        'status': false,
        'message': 'Failed to update profile',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>?> updatePasswordAPI({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final url = Uri.parse('${_baseUrl}profile/password');
      final token = await getAuthToken();

      final body = {
        'userId': userId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };

      print('Updating password for userId: $userId');
      print('Request body: ${jsonEncode(body)}');
      
      final response = await http
          .put(url, headers: _getHeaders(token: token), body: jsonEncode(body))
          .timeout(_timeout);

      print('Update password response: ${response.statusCode} - ${response.body}');
      return await _handleResponse(response);
    } catch (e) {
      print('Error updating password: $e');
      return {
        'status': false,
        'message': 'Failed to update password',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>?> uploadProfileImageAPI({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final url = Uri.parse('${_baseUrl}profile/upload-image');
      final token = await getAuthToken();

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(_getHeaders(token: token));
      request.fields['userId'] = userId;
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      print('Uploading profile image for userId: $userId');
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return await _handleResponse(response);
    } catch (e) {
      print('Error uploading profile image: $e');
      return {
        'status': false,
        'message': 'Failed to upload image',
        'error': e.toString(),
      };
    }
  }

  // ==================== PROFILE METHODS ====================

  Future<void> loadUserData() async {
    try {
      // First try to load from stored user data
      final userData = await getUserData();
      if (userData != null && userData.userId.isNotEmpty) {
        userId.value = userData.userId;
        userName.value = userData.name;
        userEmail.value = userData.email ?? '';
        userPhone.value = userData.phone ?? '';
        profileImage.value = userData.photoPath ?? '';
        
        print('Loaded user data from storage. UserId: ${userId.value}');
        return;
      }

      // If no user data, try to get just the userId
      final storedUserId = await getUserId();
      if (storedUserId != null && storedUserId.isNotEmpty) {
        userId.value = storedUserId;
        print('Found stored userId: $storedUserId, fetching profile...');
        await fetchUserProfile();
      } else {
        print('No user ID found in storage');
        _showErrorSnackbar('Please log in again');
      }
    } catch (e) {
      print('Error loading user data: $e');
      _showErrorSnackbar('Failed to load user data');
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      
      // Get current user ID - prefer the observable value if set
      String? currentUserId = userId.value.isNotEmpty ? userId.value : await getUserId();
      
      if (currentUserId == null || currentUserId.isEmpty) {
        _showErrorSnackbar('User ID not found. Please log in again.');
        return;
      }

      print('Fetching profile for user ID: $currentUserId');
      final response = await getProfileAPI(currentUserId);
      
      if (response != null && response['status'] == true) {
        final profileData = response['data'] ?? response;

        // Extract data with fallbacks for different field names
        final name = profileData['name'] ?? '';
        final email = profileData['email'] ?? profileData['email_No'] ?? '';
        final phone = profileData['phone'] ?? profileData['mobile_No'] ?? '';
        final image = profileData['photoPath'] ?? profileData['profile_image'] ?? '';
        final fetchedUserId = profileData['userId'] ?? profileData['id'] ?? currentUserId;

        // Update observable values
        userId.value = fetchedUserId;
        userName.value = name;
        userEmail.value = email;
        userPhone.value = phone;
        profileImage.value = image;

        // Save to storage
        await updateUserData(
          userId: fetchedUserId,
          name: name,
          email: email,
          phone: phone,
          profileImage: image,
        );

        print('Profile fetched successfully for user: $name (ID: $fetchedUserId)');
      } else {
        final errorMessage = response?['message'] ?? 'Failed to fetch profile';
        print('Failed to fetch profile: $errorMessage');
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      _showErrorSnackbar('Failed to fetch profile data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (name.trim().isEmpty) {
      _showErrorSnackbar('Name cannot be empty');
      return;
    }

    try {
      isLoading.value = true;
      
      // Get current user ID
      String? currentUserId = userId.value.isNotEmpty ? userId.value : await getUserId();
      
      if (currentUserId == null || currentUserId.isEmpty) {
        _showErrorSnackbar('User ID not found. Please log in again.');
        return;
      }

      print('Updating profile for user ID: $currentUserId');
      final response = await updateProfileAPI(
        userId: currentUserId,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
      );

      if (response != null && (response['status'] == true || response.containsKey('message'))) {
        // Update observable values
        userName.value = name.trim();
        userEmail.value = email.trim();
        userPhone.value = phone.trim();

        // Save to storage
        await updateUserData(
          userId: currentUserId,
          name: userName.value,
          email: userEmail.value,
          phone: userPhone.value,
        );

        final successMessage = response['message'] ?? 'Profile updated successfully';
        _showSuccessSnackbar(successMessage);
        print('Profile updated successfully for user: ${userName.value}');
      } else {
        final errorMessage = response?['message'] ?? 'Failed to update profile';
        print('Failed to update profile: $errorMessage');
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      print('Error updating profile: $e');
      _showErrorSnackbar('Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      _showErrorSnackbar('Please fill all password fields');
      return;
    }

    if (newPassword.length < 6) {
      _showErrorSnackbar('New password must be at least 6 characters');
      return;
    }

    try {
      isLoading.value = true;
      
      // Get current user ID
      String? currentUserId = userId.value.isNotEmpty ? userId.value : await getUserId();
      
      if (currentUserId == null || currentUserId.isEmpty) {
        _showErrorSnackbar('User ID not found. Please log in again.');
        return;
      }

      print('Updating password for user ID: $currentUserId');
      final response = await updatePasswordAPI(
        userId: currentUserId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (response != null && (response['status'] == true || response.containsKey('message'))) {
        final successMessage = response['message'] ?? 'Password updated successfully';
        _showSuccessSnackbar(successMessage);
        print('Password updated successfully for user ID: $currentUserId');
      } else {
        final errorMessage = response?['message'] ?? 'Failed to update password';
        print('Failed to update password: $errorMessage');
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      print('Error updating password: $e');
      _showErrorSnackbar('Failed to update password');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        isLoading.value = true;
        final file = File(pickedFile.path);

        // Get current user ID
        String? currentUserId = userId.value.isNotEmpty ? userId.value : await getUserId();
        
        if (currentUserId == null || currentUserId.isEmpty) {
          _showErrorSnackbar('User ID not found. Please log in again.');
          return;
        }

        print('Uploading profile picture for user ID: $currentUserId');
        final response = await uploadProfileImageAPI(
          userId: currentUserId,
          imageFile: file,
        );

        if (response != null && response['status'] == true) {
          final newImagePath = response['image_path'] ?? file.path;
          profileImage.value = newImagePath;
          await updateUserData(
            userId: currentUserId,
            profileImage: newImagePath,
          );
          _showSuccessSnackbar('Profile picture updated successfully');
          print('Profile picture updated successfully');
        } else {
          // Fallback: save locally if server upload fails
          profileImage.value = file.path;
          await updateUserData(
            userId: currentUserId,
            profileImage: file.path,
          );
          _showErrorSnackbar('Failed to upload to server, saved locally');
          print('Image saved locally due to server error');
        }
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      _showErrorSnackbar('Failed to update profile picture');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() async {
    print('Refreshing profile data...');
    await fetchUserProfile();
  }

  // Helper method to check if user is properly logged in
  bool get isUserLoggedIn {
    final hasUserId = userId.value.isNotEmpty;
    print('User logged in status: $hasUserId (UserId: ${userId.value})');
    return hasUserId;
  }

  // Helper method to clear user data (for logout)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('profile_image');
      
      // Clear observable values
      userId.value = '';
      userName.value = '';
      userEmail.value = '';
      userPhone.value = '';
      profileImage.value = '';
      
      print('User data cleared successfully');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}