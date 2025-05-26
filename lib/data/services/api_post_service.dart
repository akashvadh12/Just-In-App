
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:security_guard/core/api/api_client.dart';
import 'package:security_guard/core/api/api_constants.dart'; // This should provide SIGNUP_OR_LOGIN
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';

class ApiPostServices {
  final ApiClient _client = ApiClient();

  /// Centralized login method without requiring firebase token
  Future<Map<String, dynamic>> login({
    required String input,
    required String password,
    required bool loginWithPhone,
  }) async {
    const endpoint = 'Auth/UserAuthentication';
    final body = loginWithPhone
        ? {'phoneNumber': input, 'password': password}
        : {'userName': input, 'password': password};
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    log('🛜 Logging in => $endpoint, body: $body');
    final response = await _client.post(endpoint, body, headers: headers);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      log('Login API failed => ${response.body}');
    }
    return responseData;
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
    // grab token from local storage
    final token = LocalStorageService.instance.getToken();
    final Map<String, String> authHeader = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};

    // build common fields
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

    // if no photos, simple JSON POST
    if (photoPaths == null || photoPaths.isEmpty) {
      final body = fields;
      log('🛜 UpsertIncidentReport(JSON) => $fields');
      final response = await _client.post(
        UPSERT_INCIDENT_REPORT,
        body,
        headers: {'Content-Type': 'application/json', ...authHeader},
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // multipart POST when photos exist
    log('🛜 UpsertIncidentReport(Multipart) => fields:$fields photos:$photoPaths');
    final uri = Uri.parse('${_client.baseUrl}$UPSERT_INCIDENT_REPORT');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(authHeader);
    request.fields.addAll(fields);

    for (final path in photoPaths) {
      final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);
      request.files.add(await http.MultipartFile.fromPath(
        'Photo',
        path,
        filename: File(path).uri.pathSegments.last,
        contentType: mediaType,
      ));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
