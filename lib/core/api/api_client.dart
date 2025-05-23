import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
class ApiClient {
  final String baseUrl;
  ApiClient({this.baseUrl = BASE_URL});

  Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers}) async {


    print("🛜 API calling => $baseUrl$endpoint");
    final url = Uri.parse("$baseUrl$endpoint");
    final mergedHeaders = {'Content-Type': 'application/json', ...?headers};
    return await http.post(url, headers: mergedHeaders, body: jsonEncode(body));
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {


    print("🛜 API calling => $baseUrl$endpoint");
    final url = Uri.parse("$baseUrl$endpoint");
    final mergedHeaders = {'Content-Type': 'application/json', ...?headers};
    return await http.get(url, headers: mergedHeaders);
  }

  Future<http.Response> getWithParams(String endpoint, Map<String, dynamic> params,
      {Map<String, String>? headers}) async {

    print("🛜 API calling => $baseUrl$endpoint");
    final encodedParams = params.map((key, value) => MapEntry(key, value.toString().replaceAll('+', ' ')));
    final mergedHeaders = {'Content-Type': 'application/json', ...?headers};
    final uri = Uri.parse("$baseUrl$endpoint").replace(queryParameters: encodedParams);
    return await http.get(uri, headers: mergedHeaders);
  }
}
