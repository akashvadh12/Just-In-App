import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:security_guard/core/api/api_client.dart';
import 'package:security_guard/core/api/api_constants.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';

class ApiPostServices {
  final ApiClient _client = ApiClient();
  static const String _logTag = '🛜 API_POST_SERVICE';

  /// Centralized login method
  Future<Map<String, dynamic>> login({
    String? fcmId,
    required String input,
    required String password,
    required bool loginWithPhone,
  }) async {
    const endpoint = 'Auth/UserAuthentication';
    print('fcmId 😁😁😁😁😁👍👍👌: $fcmId');
    final body =
        loginWithPhone
            ? {'phoneNumber': input, 'password': password}
            : {
              'userName': input,
              'password': password,
              'notificationToken': fcmId,
            };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    log('$_logTag Login attempt => endpoint: $endpoint');
    log('$_logTag Login body: ${jsonEncode(body)}');

    try {
      final response = await _client.post(endpoint, body, headers: headers);
      final responseData = _parseResponse(response);

      if (response.statusCode == 200) {
        log('$_logTag Login successful');
      } else {
        log(
          '$_logTag Login failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return responseData;
    } catch (e) {
      log('$_logTag Login error: $e');
      rethrow;
    }
  }

  /// Send OTP for phone verification
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {
    const endpoint = 'Auth/SendOTP'; // Adjust endpoint as per your API

    final body = {'phoneNumber': phoneNumber};
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    log('$_logTag Sending OTP => phone: $phoneNumber');

    try {
      final response = await _client.post(endpoint, body, headers: headers);
      final responseData = _parseResponse(response);

      if (response.statusCode == 200) {
        log('$_logTag OTP sent successfully');
      } else {
        log('$_logTag OTP sending failed => Status: ${response.statusCode}');
      }

      return responseData;
    } catch (e) {
      log('$_logTag OTP error: $e');
      rethrow;
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    const endpoint = 'Auth/VerifyOTP'; // Adjust endpoint as per your API

    final body = {'phoneNumber': phoneNumber, 'otp': otp};

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    log('$_logTag Verifying OTP => phone: $phoneNumber');

    try {
      final response = await _client.post(endpoint, body, headers: headers);
      final responseData = _parseResponse(response);

      if (response.statusCode == 200) {
        log('$_logTag OTP verified successfully');
      } else {
        log(
          '$_logTag OTP verification failed => Status: ${response.statusCode}',
        );
      }

      return responseData;
    } catch (e) {
      log('$_logTag OTP verification error: $e');
      rethrow;
    }
  }

  /// Forgot password request
  Future<Map<String, dynamic>> forgotPassword({
    required String identifier, // email or phone
    required bool isPhone,
  }) async {
    const endpoint = 'Auth/ForgotPassword'; // Adjust as per your API

    final body = isPhone ? {'phoneNumber': identifier} : {'email': identifier};

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    log('$_logTag Forgot password request => identifier: $identifier');

    try {
      final response = await _client.post(endpoint, body, headers: headers);
      final responseData = _parseResponse(response);

      if (response.statusCode == 200) {
        log('$_logTag Forgot password request successful');
      } else {
        log(
          '$_logTag Forgot password request failed => Status: ${response.statusCode}',
        );
      }

      return responseData;
    } catch (e) {
      log('$_logTag Forgot password error: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String newPassword,
    required String otp,
    required bool isPhone,
  }) async {
    const endpoint = 'Auth/ResetPassword'; // Adjust as per your API

    final body = {
      if (isPhone) 'phoneNumber': identifier else 'email': identifier,
      'newPassword': newPassword,
      'otp': otp,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    log('$_logTag Reset password => identifier: $identifier');

    try {
      final response = await _client.post(endpoint, body, headers: headers);
      final responseData = _parseResponse(response);

      if (response.statusCode == 200) {
        log('$_logTag Password reset successful');
      } else {
        log('$_logTag Password reset failed => Status: ${response.statusCode}');
      }

      return responseData;
    } catch (e) {
      log('$_logTag Password reset error: $e');
      rethrow;
    }
  }

  /// Upsert Incident Report (JSON when no photos, multipart when photos provided)
  Future<Map<String, dynamic>> upsertIncidentReport({
    required String locationName,
    required String siteId,
    required String userId,
    required String latitude,
    required String longitude,
    required String status,
    required String companyId,
    required String description,
    List<String>? photoPaths,
  }) async {
    final headers = await _getAuthenticatedHeaders();

    final fields = {
      'LocationName': locationName,
      'SiteId': siteId,
      'UserId': userId,
      'Latitude': latitude,
      'Longitude': longitude,
      'Status': status,
      'CompanyId': companyId,
      'Description': description,
    };

    log('$_logTag Upserting incident report');
    log('$_logTag Fields: ${jsonEncode(fields)}');

    try {
      // If no photos, use simple JSON POST
      if (photoPaths == null || photoPaths.isEmpty) {
        final response = await _client.post(
          UPSERT_INCIDENT_REPORT,
          fields,
          headers: headers,
        );
        return _parseResponse(response);
      }

      // Use multipart for photos
      log('$_logTag Using multipart request with ${photoPaths.length} photos');
      return await _uploadWithPhotos(
        UPSERT_INCIDENT_REPORT,
        fields,
        photoPaths,
        headers,
      );
    } catch (e) {
      log('$_logTag Incident report error: $e');
      rethrow;
    }
  }

  /// Upload data with photos using multipart request
  Future<Map<String, dynamic>> _uploadWithPhotos(
    String endpoint,
    Map<String, String> fields,
    List<String> photoPaths,
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse('${_client.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Add headers (remove Content-Type as it's set automatically for multipart)
    final filteredHeaders = Map<String, String>.from(headers)
      ..remove('Content-Type');
    request.headers.addAll(filteredHeaders);

    // Add fields
    request.fields.addAll(fields);

    // Add photos
    for (int i = 0; i < photoPaths.length; i++) {
      final path = photoPaths[i];
      if (await File(path).exists()) {
        final mimeType = lookupMimeType(path) ?? 'image/jpeg';
        final mediaType = MediaType.parse(mimeType);

        request.files.add(
          await http.MultipartFile.fromPath(
            'Photo', // Use the same field name for all photos
            path,
            filename: 'photo_$i.${mimeType.split('/').last}',
            contentType: mediaType,
          ),
        );

        log('$_logTag Added photo: ${File(path).uri.pathSegments.last}');
      } else {
        log('$_logTag Warning: Photo file not found: $path');
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    log('$_logTag Multipart upload response status: ${response.statusCode}');
    return _parseResponse(response);
  }

  /// Get authenticated headers with token (device token only)
  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final deviceToken = LocalStorageService.instance.getDeviceToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (deviceToken != null) 'Device-Token': deviceToken,
    };
  }

  /// Parse HTTP response to Map
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return {'status': false, 'message': 'Empty response body'};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      log('$_logTag Error parsing response: $e');
      log('$_logTag Response body: ${response.body}');
      return {
        'status': false,
        'message': 'Failed to parse response',
        'error': e.toString(),
      };
    }
  }

  /// Refresh authentication token (NOOP, not supported in LocalStorageService)
  Future<Map<String, dynamic>> refreshToken() async {
    return {
      'status': false,
      'message': 'Refresh token not supported in local storage',
    };
  }

  /// Get user profile by userId

  /// Update user profile
  Future<Map<String, dynamic>?> updateProfileAPI({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    const endpoint = 'profile/update';
    final body = {
      'userId': userId,
      'name': name,
      'email': email,
      'mobile_No': phone,
    };
    final headers = await _getAuthenticatedHeaders();
    try {
      final response = await _client.put(endpoint, body, headers: headers);
      return _parseResponse(response);
    } catch (e) {
      log('$_logTag Update profile error: $e');
      return {'status': false, 'message': 'Failed to update profile'};
    }
  }

  //update company
  Future<Map<String, dynamic>?> updateCompanyAPI({
    required String companyID,
    required String companyName,
    required String industry,
    required String headquarters,
    String? latitude,
    String? longitude,
    String? radius,
    String? locationName,
    bool? status,
  }) async {
    const String endpoint = 'company/UpdateCompany'; // Ensure this is correct
    final Map<String, String> headers = await _getAuthenticatedHeaders();

    final Map<String, dynamic> body = {
      'companyID': companyID,
      'companyName': companyName,
      'industry': industry,
      'headquarters': headquarters,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radius != null) 'radius': radius,
      if (locationName != null) 'locationName': locationName,
      if (status != null) 'status': status,
    };

    try {
      final response = await _client.put(
        endpoint,
        body,
        headers: {...headers, 'Content-Type': 'application/json'},
      );
      return _parseResponse(response);
    } catch (e, stack) {
      log('$_logTag ❌ Update company error: $e\n$stack');
      return {'status': false, 'message': 'Failed to update company'};
    }
  }

  /// Update user password
  Future<Map<String, dynamic>?> updatePasswordAPI({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    const endpoint = 'profile/password';
    final body = {
      'UserId': userId,
      'OldPassword': oldPassword,
      'NewPassword': newPassword,
    };
    final headers = await _getAuthenticatedHeaders();
    try {
      final response = await _client.put(endpoint, body, headers: headers);
      return _parseResponse(response);
    } catch (e) {
      log('$_logTag Update password error: $e');
      return {'status': false, 'message': 'Failed to update password'};
    }
  }

  /// Upload profile image
  Future<Map<String, dynamic>?> uploadProfileImageAPI({
    required String userId,
    required File imageFile,
  }) async {
    const endpoint = 'profile/update-photo';
    final headers = await _getAuthenticatedHeaders();
    final uri = Uri.parse('${_client.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers..remove('Content-Type'));
    request.fields['userId'] = userId;
    request.files.add(
      await http.MultipartFile.fromPath('photo', imageFile.path),
    );
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response);
    } catch (e) {
      log('$_logTag Upload profile image error: $e');
      return {'status': false, 'message': 'Failed to upload profile image'};
    }
  }
}
