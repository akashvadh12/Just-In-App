import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:security_guard/core/api/api_client.dart';
import 'package:security_guard/modules/Compony/compony_location_controller.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class ApiGetServices {
  final ApiClient _client = ApiClient();
  static const String _logTag = '🛜 API_GET_SERVICE';

  Future<Map<String, dynamic>?> getProfileAPI(String userId) async {
    const endpoint = 'profile';
    final params = {'UserId': userId};
    final headers = await _getAuthenticatedHeaders();
    try {
      final response = await _client.getWithParams(
        endpoint,
        params,
        headers: headers,
      );
      return _parseResponse(response);
    } catch (e) {
      log('$_logTag Get profile error: $e');
      return {'status': false, 'message': 'Failed to get profile'};
    }
  }


// Add this method to your existing ApiService class

/// Send live location data to server
Future<http.Response> sendLiveLocation(Map<String, dynamic> locationData) async {
  const String endpoint = 'Tracking/live-tracking';
  
  // Ensure required fields are present
  final Map<String, dynamic> body = {
    'userId': locationData['userId'],
    'latitude': locationData['latitude'] ?? 0.0,
    'longitude': locationData['longitude'] ?? 0.0,
    'isClockedIn': locationData['isClockedIn'] ?? false,
    'isClockedOut': locationData['isClockedOut'] ?? false,
 
  
  };

  try {
    log('[ApiService] Sending live location: ${jsonEncode(body)}');
    final response = await  _client.post(endpoint, body);
    log('[ApiService] Live location response: ${response.statusCode} - ${response.body}');
    return response;
  } catch (e) {
    log('[ApiService] Error sending live location: $e');
    rethrow;
  }
}


Future<http.Response> sendSafetyCheckIn(Map<String, dynamic> checkInData) async {
  const String endpoint = 'Tracking/safety-checkin';
  
  // Ensure required fields are present with proper structure
  final Map<String, dynamic> body = {
    'userId': checkInData['userId'] ?? '',
    'latitude': checkInData['latitude'] ?? 0.0,
    'longitude': checkInData['longitude'] ?? 0.0,
    'promptTime': checkInData['promptTime'] ?? DateTime.now().toIso8601String(),
    'response': checkInData['response'] ?? 'AllOK',
  };

  try {
    log('[ApiService] Sending safety check-in: ${jsonEncode(body)}');
    final response = await _client.post(endpoint, body);
    log('[ApiService] Safety check-in response: ${response.statusCode} - ${response.body}');
    return response;
  } catch (e) {
    log('[ApiService] Error sending safety check-in: $e');
    rethrow;
  }
}

  Future<http.Response> getOfficeLocRaw() async {
    const endpoint = 'CompanyConfig/GetOfficeLoc';
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Get Office Location Raw request => endpoint: $endpoint');

    try {
      final response = await _client.get(endpoint, headers: headers);

      if (response.statusCode == 200) {
        log('$_logTag Get Office Location Raw successful');
      } else {
        log(
          '$_logTag Get Office Location Raw failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Get Office Location Raw error: $e');
      rethrow;
    }
  }

  // Get Attendance History API - Raw Response (for minimal changes)
  Future<http.Response> getAttendanceHistoryRaw({
    required String userId,
    required String month,
  }) async {
    const endpoint = 'AttendanceRecord/attendance/history';
    final params = {'userId': userId, 'month': month};
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Get Attendance History Raw request => endpoint: $endpoint');
    log('$_logTag Attendance History params: $params');

    try {
      final response = await _client.getWithParams(
        endpoint,
        params,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Get Attendance History Raw successful');
      } else {
        log(
          '$_logTag Get Attendance History Raw failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Get Attendance History Raw error: $e');
      rethrow;
    }
  }

  Future<http.Response> getTodayAttendanceRaw({required String userId}) async {
    final endpoint = 'AttendanceRecord/attendance/today/$userId';
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Get Today Attendance Raw request => endpoint: $endpoint');

    try {
      final response = await _client.get(endpoint, headers: headers);

      if (response.statusCode == 200) {
        log('$_logTag Get Today Attendance Raw successful');
      } else {
        log(
          '$_logTag Get Today Attendance Raw failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Get Today Attendance Raw error: $e');
      rethrow;
    }
  }

  // Get Attendance Report API - Raw Response (for minimal changes)
  Future<http.Response> getAttendanceReportRaw({
    required String userId,
    required String fromDate,
    required String toDate,
  }) async {
    const endpoint = 'AttendanceRecord/attendance/report';
    final params = {'userId': userId, 'fromDate': fromDate, 'toDate': toDate};
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Get Attendance Report Raw request => endpoint: $endpoint');
    log('$_logTag Attendance Report params: $params');

    try {
      final response = await _client.getWithParams(
        endpoint,
        params,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Get Attendance Report Raw successful');
      } else {
        log(
          '$_logTag Get Attendance Report Raw failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Get Attendance Report Raw error: $e');
      rethrow;
    }
  }

  // Mark Attendance API - Raw Response (for minimal changes with multipart)
  Future<http.Response> markAttendanceRaw({
    required String userId,
    required String type,
    required String latitude,
    required String longitude,
    required String selfieBase64,
    required File selfieFile,
    String? entryTimestamp,
    String? exitTimestamp,
  }) async {
    const endpoint =
        'AttendanceRecord/attendance/mark'; // Adjust endpoint as needed
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Mark Attendance Raw request => endpoint: $endpoint');
    log('$_logTag Mark Attendance type: $type, userId: $userId');

    try {
      // Prepare form fields
      final fields = <String, String>{
        'UserId': userId,
        'Type': type,
        'Latitude': latitude,
        'Longitude': longitude,
        'SelfieBase64': selfieBase64,
      };

      if (entryTimestamp != null) {
        fields['EntryTimestamp'] = entryTimestamp;
      }
      if (exitTimestamp != null) {
        fields['ExitTimestamp'] = exitTimestamp;
      }

      // Prepare file
      final multipartFile = await http.MultipartFile.fromPath(
        'SelfieFile',
        selfieFile.path,
        filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final response = await _client.postMultipart(endpoint, fields, [
        multipartFile,
      ], headers: headers);

      if (response.statusCode == 200) {
        log('$_logTag Mark Attendance Raw successful');
      } else {
        log(
          '$_logTag Mark Attendance Raw failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Mark Attendance Raw error: $e');
      rethrow;
    }
  }

  // Forgot Password API - Raw Response (for minimal changes)
  Future<http.Response> forgotPasswordRaw({
    required String phoneOrEmployeeId,
  }) async {
    final encodedEmail = Uri.encodeComponent(phoneOrEmployeeId);
    final endpoint = 'Auth/forgot-password?email=$encodedEmail';
    final headers = <String, String>{'Content-Type': 'application/json'};

    log('$_logTag Forgot Password request => endpoint: $endpoint');
    log('$_logTag Phone/Employee ID: $phoneOrEmployeeId');

    try {
      final response = await _client.postWithoutBody(
        endpoint,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Forgot Password successful');
      } else {
        log(
          '$_logTag Forgot Password failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Forgot Password error: $e');
      rethrow;
    }
  }

  Future<http.Response> fetchIssuesRaw({
    String status = 'all',
    required int page,
  }) async {
    const endpoint = 'IssuesRecord'; // Replace with your actual endpoint
    final params = {'status': status, 'page': page.toString()};
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Fetch Issues request => endpoint: $endpoint');
    log('$_logTag Issues params: $params');

    try {
      final response = await _client.getWithParams(
        endpoint,
        params,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Fetch Issues successful');
      } else {
        log(
          '$_logTag Fetch Issues failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Fetch Issues error: $e');
      rethrow;
    }
  }

  Future<http.Response> upsertIncidentReportRaw({
    required Map<String, dynamic> data,
  }) async {
    const endpoint = 'Admin/UpsertIncidentReport';
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Upsert Incident Report request => endpoint: $endpoint');
    log('$_logTag Request data: ${jsonEncode(data)}');

    try {
      final response = await _client.post(endpoint, data, headers: headers);

      if (response.statusCode == 200) {
        log('$_logTag Upsert Incident Report successful');
      } else {
        log(
          '$_logTag Upsert Incident Report failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Upsert Incident Report error: $e');
      rethrow;
    }
  }

  // Submit Incident Report API - Using your existing working logic
  Future<http.Response> submitIncidentReportRaw({
    required String userId,
    required String latitude,
    required String longitude,
    required String description,
    required List<XFile> photos,
    required List<Uint8List> imageBytesList,
  }) async {
    const endpoint = 'IssuesRecord/create';
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Submit Incident Report request => endpoint: $endpoint');
    log('$_logTag UserId: $userId, Description length: ${description.length}');

    try {
      // Prepare form fields
      final fields = <String, String>{
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      };

      // Use your existing working file handling logic
      final multipartFiles = <http.MultipartFile>[];

      for (int i = 0; i < imageBytesList.length; i++) {
        final photo = photos[i];
        final bytes = imageBytesList[i];

        // Copy your exact working logic from _submitWithImages
        final mimeType = lookupMimeType(photo.path) ?? 'image/jpeg';
        final mediaType = MediaType.parse(mimeType);

        final file = http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: path.basename(photo.path),
          contentType: mediaType,
        );

        multipartFiles.add(file);
      }

      final response = await _client.postMultipart(
        endpoint,
        fields,
        multipartFiles,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Submit Incident Report successful');
      } else {
        log(
          '$_logTag Submit Incident Report failed => Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Submit Incident Report error: $e');
      rethrow;
    }
  }

  Future<http.Response> fetchNotificationsRaw() async {
    const endpoint = 'Notification/top-list';
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Fetch Notifications request => endpoint: $endpoint');

    try {
      final response = await _client.get(endpoint, headers: headers);

      if (response.statusCode == 200) {
        log('$_logTag Fetch Notifications successful');
      } else {
        log(
          '$_logTag Fetch Notifications failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Fetch Notifications error: $e');
      rethrow;
    }
  }

  // Stop Patrol API (Raw Response)
  Future<http.Response> stopPatrolRaw({
    required String userId,
    required String remarks,
  }) async {
    const endpoint = 'patrol/checkout';
    final headers = await _getAuthenticatedHeaders();

    // Build request body
    final requestBody = {
      "userID": userId,
      "remarks": remarks.isEmpty ? "Patrol stopped" : remarks,
    };

    log('$_logTag Stop Patrol request => endpoint: $endpoint');
    log('$_logTag Stop Patrol body => $requestBody');

    try {
      // ✅ Use your custom post wrapper correctly
      final response = await _client.post(
        endpoint,
        requestBody, // 👈 pass as second positional argument (Map, not jsonEncode)
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Stop Patrol successful');
      } else {
        log(
          '$_logTag Stop Patrol failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Stop Patrol error: $e');
      rethrow;
    }
  }

  Future<http.Response> fetchPatrolHistory({
    String? logId,
    bool isRefresh = false,
  }) async {
    const endpoint = 'Patrol/history';
    final headers = await _getAuthenticatedHeaders();

    final params = <String, String>{};
    if (logId != null && logId.isNotEmpty && !isRefresh) {
      params['logId'] = logId;
    }

    log(
      '$_logTag Fetch Patrol History => endpoint: $endpoint, params: $params',
    );

    try {
      final response = await _client.getWithParams(
        endpoint,
        params,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Fetch Patrol History successful');
      } else {
        log(
          '$_logTag Fetch Patrol History failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Fetch Patrol History error: $e');
      rethrow;
    }
  }

  // 3. Fetch User Patrol History (date range)
  Future<http.Response> fetchUserPatrolHistory({
    required String userId,
    required String startDate,
    required String endDate,
  }) async {
    const endpoint = 'patrol/Userhistory';
    final headers = await _getAuthenticatedHeaders();

    final params = {'start': startDate, 'end': endDate, 'UserId': userId};

    log(
      '$_logTag Fetch User Patrol History => endpoint: $endpoint, params: $params',
    );

    try {
      final response = await _client.getWithParams(
        endpoint,
        params,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Fetch User Patrol History successful');
      } else {
        log(
          '$_logTag Fetch User Patrol History failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Fetch User Patrol History error: $e');
      rethrow;
    }
  }

  // 4. Fetch Patrol History Details (by logId)
  Future<http.Response> fetchHistoryDetails(String logId) async {
    const endpoint = 'patrol/history';
    final headers = await _getAuthenticatedHeaders();

    final params = {'logId': logId};

    log(
      '$_logTag Fetch History Details => endpoint: $endpoint, params: $params',
    );

    try {
      final response = await _client.getWithParams(
        endpoint,
        params,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Fetch History Details successful');
      } else {
        log(
          '$_logTag Fetch History Details failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Fetch History Details error: $e');
      rethrow;
    }
  }

  /// ✅ Patrol Check-in (normal flow)
  Future<http.Response> patrolCheckin({
    required String userId,
    required String logId,
    required String locationId,
    required String latitude,
    required String longitude,
    required String note,
    required bool isLastPatrol,
    required File selfie,
  }) async {
    final fields = {
      'UserID': userId,
      'Log_Id': logId,
      'LocationId': locationId,
      'Latitude': latitude,
      'Longitude': longitude,
      'Note': note,
      'ActivePatrol': isLastPatrol ? 'false' : 'true',
    };

    final files = <http.MultipartFile>[
      await http.MultipartFile.fromPath('Selfie', selfie.path),
    ];

    return _client.postMultipart('patrol/checkin', fields, files);
  }

  /// ✅ Patrol Unknown / Manual Check-in
  Future<http.Response> patrolUnknownCheckin({
    required String userId,
    required String logId,
    required String manualLocationName,
    required String latitude,
    required String longitude,
    required String note,
    required File selfie,
  }) async {
    final fields = {
      'UserID': userId,
      'Log_Id': logId,
      'ManualLocationName': manualLocationName,
      'ManualLatitude': latitude,
      'ManualLongitude': longitude,
      'Note': note,
      'ActivePatrol': 'true',
      'LocationId': '',
    };

    final files = <http.MultipartFile>[
      await http.MultipartFile.fromPath('Selfie', selfie.path),
    ];

    return _client.postMultipart('patrol/unknown-checkin', fields, files);
  }

  Future<List<CompanyLocation>> getCompanyLocations() async {
    final response = await _client.get('CompanyConfig/GetCompanyLoc');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CompanyLocation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch company locations: ${response.body}');
    }
  }

  Future<http.Response> addCompanyLocation({
    // required String companyName,
    // required String industry,
    // required String headquarters,
    required String locationName,
    required String latitude,
    required String longitude,
    required String radius,
    required String userId,
    String? issueRadius,
  }) async {
    const String endpoint = 'CompanyConfig/InsertMultipleCompanyLocation';

    final Map<String, dynamic> body = {
      // 'companyName': companyName,
      // 'industry': industry,
      // 'headquarters': headquarters,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'radius': radius,
      'issue_radius':
          issueRadius ?? radius, // Use radius as default if not provided
    };

    return _client.post(endpoint, body);
  }

  Future<http.Response> updateLocationRaw({
    required String companyID,
    required String companyName,
    required String industry,
    required String headquarters,
    required String locationName,
    required String finalLatitude,
    required String finalLongitude,
    required String finalRadius,
    required String userId,
    required bool finalStatus,
    required File photo,
  }) async {
    const endpoint = 'Loaction/update'; // ⚠️ check spelling ("Location"?)
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Update Location Raw request => endpoint: $endpoint');

    try {
      // Prepare fields
      final fields = <String, String>{
        'Company_ID': companyID,
        'Company_Name': companyName,
        'Industry': industry,
        'Headquarters': headquarters,
        'Location_Name': locationName,
        'Latitude': finalLatitude,
        'Longitude': finalLongitude,
        'Radius': finalRadius,
        'UserId': userId,
        'Status': finalStatus.toString(),
      };

      // Prepare file
      final multipartFile = await http.MultipartFile.fromPath(
        'Photos',
        photo.path,
        filename: 'location_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Use client’s postMultipart (you can also create putMultipart if needed)
      final response = await _client.postMultipart(endpoint, fields, [
        multipartFile,
      ], headers: headers);

      if (response.statusCode == 200) {
        log('$_logTag Update Location Raw successful');
      } else {
        log(
          '$_logTag Update Location Raw failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      return response;
    } catch (e) {
      log('$_logTag Update Location Raw error: $e');
      rethrow;
    }
  }

  /// Fetch all locations
  Future<http.Response> fetchLocationsRaw() async {
    const endpoint = 'Loaction/all'; // ⚠️ check spelling: maybe "Location/all"
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Fetch Locations request => endpoint: $endpoint');

    try {
      final response = await _client.get(endpoint, headers: headers);

      if (response.statusCode == 200) {
        log('$_logTag Fetch Locations successful');
      } else {
        log(
          '$_logTag Fetch Locations failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
      return response;
    } catch (e) {
      log('$_logTag Fetch Locations error: $e');
      rethrow;
    }
  }

  /// Add new location (multipart)
  Future<http.Response> addLocationRaw({
    required String locationName,
    required String latitude,
    required String longitude,
    required String radius,
    required String userId,
    File? photo,
  }) async {
    const endpoint = 'Loaction/add';
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Add Location request => endpoint: $endpoint');

    try {
      final fields = <String, String>{
        'Location_Name': locationName,
        'Latitude': latitude,
        'Longitude': longitude,
        'Radius': radius,
        'UserId': userId,
      };

      final files = <http.MultipartFile>[];
      if (photo != null) {
        files.add(await http.MultipartFile.fromPath('Photos', photo.path));
      }

      final response = await _client.postMultipart(
        endpoint,
        fields,
        files,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Add Location successful');
      } else {
        log(
          '$_logTag Add Location failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
      return response;
    } catch (e) {
      log('$_logTag Add Location error: $e');
      rethrow;
    }
  }

  /// Update existing location (multipart PUT)
  Future<http.Response> updateLocationRawByAdmin({
    required String locationId,
    required String locationName,
    String? latitude,
    String? longitude,
    String? radius,
    required String userId,
    File? photo,
  }) async {
    const endpoint = 'Loaction/update';
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Update Location request => endpoint: $endpoint');

    try {
      final fields = <String, String>{
        'Location_Id': locationId,
        'Location_Name': locationName,
        'Latitude': latitude ?? '',
        'Longitude': longitude ?? '',
        'Radius': radius ?? '',
        'UserId': userId,
      };

      final files = <http.MultipartFile>[];
      if (photo != null) {
        files.add(await http.MultipartFile.fromPath('Photos', photo.path));
      }

      // ⚠️ Your ApiClient doesn’t yet have putMultipart, only postMultipart
      // Option 1: Add putMultipart in ApiClient (recommended)
      // Option 2: Use postMultipart if backend accepts POST for update

      final response = await _client.putMultipart(
        endpoint,
        fields,
        files,
        headers: headers,
      );

      if (response.statusCode == 200) {
        log('$_logTag Update Location successful');
      } else {
        log(
          '$_logTag Update Location failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
      return response;
    } catch (e) {
      log('$_logTag Update Location error: $e');
      rethrow;
    }
  }

  /// Delete location
  Future<http.Response> deleteLocationRaw(String locationId) async {
    final endpoint = 'Loaction/delete/$locationId';
    final headers = await _getAuthenticatedHeaders();

    log('$_logTag Delete Location request => endpoint: $endpoint');

    try {
      final response = await _client.delete(endpoint, headers: headers);

      if (response.statusCode == 200) {
        log('$_logTag Delete Location successful');
      } else {
        log(
          '$_logTag Delete Location failed => '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
      return response;
    } catch (e) {
      log('$_logTag Delete Location error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final deviceToken = LocalStorageService.instance.getDeviceToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (deviceToken != null) 'Device-Token': deviceToken,
    };
  }

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
}
