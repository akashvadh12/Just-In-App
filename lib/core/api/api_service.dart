import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'api_constants.dart';

class ApiService {
  final String baseUrl;
  final LocalStorageService _storage = LocalStorageService.instance;
  
  ApiService({this.baseUrl = BASE_URL});
  
  // Get auth token from storage
  Future<String?> _getAuthToken() async {
    return _storage.getToken();
  }
  
  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // POST request with auth token
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();
    
    print("🛜 API calling => $baseUrl$endpoint");
    return await http.post(
      url, 
      headers: headers, 
      body: jsonEncode(body)
    );
  }
  
  // GET request with auth token
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();
    
    print("🛜 API calling => $baseUrl$endpoint");
    return await http.get(url, headers: headers);
  }
  
  // GET request with parameters and auth token
  Future<http.Response> getWithParams(String endpoint, Map<String, dynamic> params) async {
    final encodedParams = params.map((key, value) => MapEntry(key, value.toString().replaceAll('+', ' ')));
    final uri = Uri.parse("$baseUrl$endpoint").replace(queryParameters: encodedParams);
    final headers = await _getHeaders();
    
    print("🛜 API calling => $uri");
    return await http.get(uri, headers: headers);
  }
  
  // Helper method to log API responses
  void logResponse(String endpoint, dynamic response, {dynamic error}) {
    if (error != null) {
      print('📡 API Error [$endpoint]: $error');
      return;
    }
    
    print('📡 API Response [$endpoint]: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');
  }
}
