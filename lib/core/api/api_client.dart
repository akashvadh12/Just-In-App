import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/data/services/session_service.dart';
import 'api_constants.dart';

class ApiClient {
  final String baseUrl;
  final int timeoutSeconds;
  final int maxRetries;

  ApiClient({
    this.baseUrl = BASE_URL,
    this.timeoutSeconds = 30,
    this.maxRetries = 3,
  });

  static const String _logTag = '🛜 API_CLIENT';
  final SessionService _sessionService = Get.find<SessionService>();

  /// POST request with retry logic (updated to include session data)
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      final connectivityController = Get.find<ConnectivityController>();

      if (connectivityController.isOffline.value) {
        return http.Response('No internet connection', 503);
      }

      log('$_logTag POST => $baseUrl$endpoint');

      // Add company and site IDs to body if available and not already present
      final updatedBody = Map<String, dynamic>.from(body);
      if (_sessionService.companyId != null &&
          !updatedBody.containsKey('companyId')) {
        updatedBody['companyId'] = _sessionService.companyId!;
      }
      if (_sessionService.siteId != null &&
          !updatedBody.containsKey('siteId')) {
        updatedBody['siteId'] = _sessionService.siteId!;
      }

      log('$_logTag Request body: ${jsonEncode(updatedBody)}');

      final url = Uri.parse('$baseUrl$endpoint');
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .post(url, headers: mergedHeaders, body: jsonEncode(updatedBody))
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// GET request with query parameters (updated to include session data)
  Future<http.Response> getWithParams(
    String endpoint,
    Map<String, dynamic> params, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      final connectivityController = Get.find<ConnectivityController>();

      if (connectivityController.isOffline.value) {
        return http.Response('No internet connection', 503);
      }
      // Add company and site IDs to params if available and not already present
      final updatedParams = Map<String, dynamic>.from(params);
      if (_sessionService.companyId != null &&
          !updatedParams.containsKey('CompanyId')) {
        updatedParams['CompanyId'] = _sessionService.companyId!;
      }
      if (_sessionService.siteId != null &&
          !updatedParams.containsKey('SiteId')) {
        updatedParams['SiteId'] = _sessionService.siteId!;
      }

      final cleanParams = _cleanParams(updatedParams);
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: cleanParams);

      log('$_logTag GET with params => $uri');

      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .get(uri, headers: mergedHeaders)
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// GET request (updated to include session data as query parameters)
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      final connectivityController = Get.find<ConnectivityController>();

      if (connectivityController.isOffline.value) {
        return http.Response('No internet connection', 503);
      }
      // Build query parameters with company and site IDs
      final queryParams = <String, String>{};
      if (_sessionService.companyId != null) {
        queryParams['CompanyId'] = _sessionService.companyId!;
      }
      if (_sessionService.siteId != null) {
        queryParams['SiteId'] = _sessionService.siteId!;
      }

      final uri =
          queryParams.isNotEmpty
              ? Uri.parse(
                '$baseUrl$endpoint',
              ).replace(queryParameters: queryParams)
              : Uri.parse('$baseUrl$endpoint');

      log('$_logTag GET => $uri');

      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .get(uri, headers: mergedHeaders)
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// PUT request (updated to include session data)
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      final connectivityController = Get.find<ConnectivityController>();

      if (connectivityController.isOffline.value) {
        return http.Response('No internet connection', 503);
      }
      log('$_logTag PUT => $baseUrl$endpoint');

      // Add company and site IDs to body if available and not already present
      final updatedBody = Map<String, dynamic>.from(body);
      if (_sessionService.companyId != null &&
          !updatedBody.containsKey('companyId')) {
        updatedBody['companyId'] = _sessionService.companyId!;
      }
      if (_sessionService.siteId != null &&
          !updatedBody.containsKey('siteId')) {
        updatedBody['siteId'] = _sessionService.siteId!;
      }

      log('Request body:👍👍👍👍 ${jsonEncode(updatedBody)}');

      final url = Uri.parse('$baseUrl$endpoint');
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .put(url, headers: mergedHeaders, body: jsonEncode(updatedBody))
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// Multipart POST request (for file uploads)
  Future<http.Response> postMultipart(
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      final connectivityController = Get.find<ConnectivityController>();

      if (connectivityController.isOffline.value) {
        return http.Response('No internet connection', 503);
      }
      log('$_logTag POST Multipart => $baseUrl$endpoint');

      // Add company and site IDs to fields if available and not already present
      final updatedFields = Map<String, String>.from(fields);
      if (_sessionService.companyId != null &&
          !updatedFields.containsKey('CompanyId')) {
        updatedFields['CompanyId'] = _sessionService.companyId!;
      }
      if (_sessionService.siteId != null &&
          !updatedFields.containsKey('SiteId')) {
        updatedFields['SiteId'] = _sessionService.siteId!;
      }

      log('Multipart fields:👍👍👍👍👍👍 $updatedFields');

      final uri = Uri.parse('$baseUrl$endpoint');
      var request = http.MultipartRequest('POST', uri);

      // Add headers (excluding Content-Type as it's set automatically for multipart)
      final customHeaders = Map<String, String>.from(headers ?? {});
      customHeaders.remove('Content-Type'); // Let http package set this

      final mergedHeaders = _buildHeaders(customHeaders);
      mergedHeaders.remove('Content-Type'); // Remove again to be safe
      request.headers.addAll(mergedHeaders);

      // Add fields
      request.fields.addAll(updatedFields);

      // Add files
      request.files.addAll(files);

      log('$_logTag Sending multipart request with ${files.length} files');

      final streamedResponse = await request.send().timeout(
        Duration(seconds: timeoutSeconds),
      );
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(endpoint, response);
      return response;
    });
  }

  Future<http.Response> postWithoutBody(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      final connectivityController = Get.find<ConnectivityController>();

      if (connectivityController.isOffline.value) {
        return http.Response('No internet connection', 503);
      }
      log('$_logTag POST (no body) => $baseUrl$endpoint');

      final url = Uri.parse('$baseUrl$endpoint');
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .post(url, headers: mergedHeaders)
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// PUT request
  Future<http.Response> companyPut(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      final connectivityController = Get.find<ConnectivityController>();

      if (connectivityController.isOffline.value) {
        return http.Response('No internet connection', 503);
      }
      log('$_logTag PUT => $baseUrl$endpoint');
      log('$_logTag Request body (before enrich): ${jsonEncode(body)}');

      // ✅ Copy body so we don't mutate the caller's map
      final updatedBody = Map<String, dynamic>.from(body);

      // ✅ Inject CompanyId and SiteId if available and not already set
      if (_sessionService.companyId != null &&
          !updatedBody.containsKey('CompanyId')) {
        updatedBody['CompanyId'] = _sessionService.companyId!;
      }
      if (_sessionService.siteId != null &&
          !updatedBody.containsKey('SiteId')) {
        updatedBody['SiteId'] = _sessionService.siteId!;
      }

      log('$_logTag Request body (after enrich): ${jsonEncode(updatedBody)}');

      final url = Uri.parse('${BASE_URL}CompanyConfig/UpdateCompany');
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .put(url, headers: mergedHeaders, body: jsonEncode(updatedBody))
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  Future<http.Response> putMultipart(
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
         final connectivityController = Get.find<ConnectivityController>();

      if (connectivityController.isOffline.value) {
        return http.Response('No internet connection', 503);
      }
      log('$_logTag PUT Multipart => $baseUrl$endpoint');

      // Add company and site IDs if missing
      final updatedFields = Map<String, String>.from(fields);
      if (_sessionService.companyId != null &&
          !updatedFields.containsKey('CompanyId')) {
        updatedFields['CompanyId'] = _sessionService.companyId!;
      }
      if (_sessionService.siteId != null &&
          !updatedFields.containsKey('SiteId')) {
        updatedFields['SiteId'] = _sessionService.siteId!;
      }

      log('Multipart fields (PUT): $updatedFields');

      final uri = Uri.parse('$baseUrl$endpoint');
      var request = http.MultipartRequest('PUT', uri);

      // Headers
      final customHeaders = Map<String, String>.from(headers ?? {});
      customHeaders.remove('Content-Type'); // Let http package set this
      final mergedHeaders = _buildHeaders(customHeaders);
      mergedHeaders.remove('Content-Type');
      request.headers.addAll(mergedHeaders);

      // Add fields + files
      request.fields.addAll(updatedFields);
      request.files.addAll(files);

      final streamedResponse = await request.send().timeout(
        Duration(seconds: timeoutSeconds),
      );
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// DELETE request
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      log('$_logTag DELETE => $baseUrl$endpoint');

      final url = Uri.parse('$baseUrl$endpoint');
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .delete(url, headers: mergedHeaders)
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// PATCH request
  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      log('$_logTag PATCH => $baseUrl$endpoint');
      log('$_logTag Request body: ${jsonEncode(body)}');

      final url = Uri.parse('$baseUrl$endpoint');
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .patch(url, headers: mergedHeaders, body: jsonEncode(body))
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// Execute request with retry logic
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        final response = await request();

        // Return response if successful or client error (4xx)
        if (response.statusCode < 500) {
          return response;
        }

        // For server errors (5xx), retry if not the last attempt
        if (attempts < maxRetries) {
          final delay = Duration(seconds: attempts * 2); // Exponential backoff
          log(
            '$_logTag Server error ${response.statusCode}, retrying in ${delay.inSeconds}s (attempt $attempts/$maxRetries)',
          );
          await Future.delayed(delay);
          continue;
        }

        return response;
      } on SocketException catch (e) {
        log('$_logTag Network error (attempt $attempts/$maxRetries): $e');
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      } on HttpException catch (e) {
        log('$_logTag HTTP error (attempt $attempts/$maxRetries): $e');
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      } catch (e) {
        log('$_logTag Unexpected error (attempt $attempts/$maxRetries): $e');
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }

    throw Exception('Max retry attempts ($maxRetries) exceeded');
  }

  /// Build request headers
  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'SecurityGuard-Mobile-App',
      'Accept-Encoding': 'gzip, deflate',
    };

    if (headers != null) {
      return {...defaultHeaders, ...headers};
    }

    return defaultHeaders;
  }

  /// Clean query parameters
  Map<String, String> _cleanParams(Map<String, dynamic> params) {
    return params.map((key, value) {
      final cleanValue = value.toString().replaceAll('+', ' ').trim();
      return MapEntry(key, cleanValue);
    });
  }

  /// Log API response
  void _logResponse(String endpoint, http.Response response) {
    final statusCode = response.statusCode;
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';

    log('$_logTag $emoji Response [$statusCode] for $endpoint');

    if (statusCode >= 400) {
      log('$_logTag Error response body: ${response.body}');
    } else {
      // Only log response body in debug mode to avoid cluttering logs
      final bodyPreview =
          response.body.length > 200
              ? '${response.body.substring(0, 200)}...'
              : response.body;
      log('$_logTag Response preview: $bodyPreview');
    }
  }

  /// Check if response is successful
  bool isSuccessful(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Parse JSON response safely
  Map<String, dynamic>? parseJsonResponse(http.Response response) {
    try {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      log('$_logTag Error parsing JSON response: $e');
      return null;
    }
  }
}
