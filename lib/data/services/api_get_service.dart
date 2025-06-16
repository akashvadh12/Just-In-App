
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:security_guard/core/api/api_client.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'package:security_guard/shared/widgets/Custom_Snackbar/Custom_Snackbar.dart';

class ApiGetServices {
  final ApiClient _client = ApiClient();
  static const String _logTag = '🛜 API_GET_SERVICE';

  Future<Map<String, dynamic>?> getProfileAPI(String userId) async {
    const endpoint = 'profile';
    final params = {'UserId': userId};
    final headers = await _getAuthenticatedHeaders();
    try {
      final response = await _client.getWithParams(endpoint, params, headers: headers);
      return _parseResponse(response);
    } catch (e) {
      log('$_logTag Get profile error: $e');
      return {'status': false, 'message': 'Failed to get profile'};
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