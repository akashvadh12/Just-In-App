import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
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

  /// POST request with retry logic
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      log('$_logTag POST => $baseUrl$endpoint');
      log('$_logTag Request body: ${jsonEncode(body)}');

      final url = Uri.parse('$baseUrl$endpoint');
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .post(url, headers: mergedHeaders, body: jsonEncode(body))
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// GET request with retry logic
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      log('$_logTag GET => $baseUrl$endpoint');

      final url = Uri.parse('$baseUrl$endpoint');
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .get(url, headers: mergedHeaders)
          .timeout(Duration(seconds: timeoutSeconds));

      _logResponse(endpoint, response);
      return response;
    });
  }

  /// GET request with query parameters
  Future<http.Response> getWithParams(
    String endpoint,
    Map<String, dynamic> params, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      final cleanParams = _cleanParams(params);
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

  /// PUT request
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() async {
      log('$_logTag PUT => $baseUrl$endpoint');
      log('$_logTag Request body: ${jsonEncode(body)}');

      final url = Uri.parse('$baseUrl$endpoint');

      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .put(url, headers: mergedHeaders, body: jsonEncode(body))
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
      log('$_logTag PUT => $baseUrl$endpoint');
      log('$_logTag Request body: ${jsonEncode(body)}');

      final url = Uri.parse(
        'https://justin.solarvision-cairo.com/api/CompanyConfig/UpdateCompany',
      );
      final mergedHeaders = _buildHeaders(headers);

      final response = await http
          .put(url, headers: mergedHeaders, body: jsonEncode(body))
          .timeout(Duration(seconds: timeoutSeconds));

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
