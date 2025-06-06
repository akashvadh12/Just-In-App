// // ==================== API SERVICE ====================
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';

// class ApiService {
//   static const String _baseUrl = "https://official.solarvision-cairo.com/api/";
//   static const Duration _timeout = Duration(seconds: 30);

//   // ==================== HELPER METHODS ====================
  
//   Map<String, String> _getHeaders({String? token}) {
//     final headers = {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//     };
    
//     if (token != null && token.isNotEmpty) {
//       headers['Authorization'] = 'Bearer $token';
//     }
    
//     return headers;
//   }

//   Future<Map<String, dynamic>?> _handleResponse(http.Response response) async {
//     try {
//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         if (response.body.isNotEmpty) {
//           return jsonDecode(response.body) as Map<String, dynamic>;
//         }
//         return {'status': true, 'message': 'Success'};
//       } else {
//         print('API Error: ${response.statusCode} - ${response.body}');
//         return {
//           'status': false,
//           'message': 'Server error: ${response.statusCode}',
//           'error_code': response.statusCode
//         };
//       }
//     } catch (e) {
//       print('Error parsing response: $e');
//       return {
//         'status': false,
//         'message': 'Failed to parse server response',
//         'error': e.toString()
//       };
//     }
//   }

//   // ==================== PROFILE METHODS ====================
  
//   Future<Map<String, dynamic>?> getProfile(String userId) async {
//     try {
//       final url = Uri.parse('${_baseUrl}profile?UserId=$userId');
//       final token = LocalStorageService.instance.getToken();
      
//       final response = await http.get(
//         url,
//         headers: _getHeaders(token: token),
//       ).timeout(_timeout);

//       return await _handleResponse(response);
//     } catch (e) {
//       print('Error getting profile: $e');
//       return {
//         'status': false,
//         'message': 'Failed to fetch profile',
//         'error': e.toString()
//       };
//     }
//   }

//   Future<Map<String, dynamic>?> updateProfile({
//     required String userId,
//     required String name,
//     required String email,
//     required String phone,
//   }) async {
//     try {
//       final url = Uri.parse('${_baseUrl}profile/update');
//       final token = LocalStorageService.instance.getToken();
      
//       final body = {
//         'userId': userId,
//         'name': name,
//         'email': email,
//         'mobile_No': phone,
//       };

//       final response = await http.post(
//         url,
//         headers: _getHeaders(token: token),
//         body: jsonEncode(body),
//       ).timeout(_timeout);

//       return await _handleResponse(response);
//     } catch (e) {
//       print('Error updating profile: $e');
//       return {
//         'status': false,
//         'message': 'Failed to update profile',
//         'error': e.toString()
//       };
//     }
//   }

//   Future<Map<String, dynamic>?> updatePassword({
//     required String userId,
//     required String oldPassword,
//     required String newPassword,
//   }) async {
//     try {
//       final url = Uri.parse('${_baseUrl}profile/password');
//       final token = LocalStorageService.instance.getToken();
      
//       final body = {
//         'userId': userId,
//         'oldPassword': oldPassword,
//         'newPassword': newPassword,
//       };

//       final response = await http.post(
//         url,
//         headers: _getHeaders(token: token),
//         body: jsonEncode(body),
//       ).timeout(_timeout);

//       return await _handleResponse(response);
//     } catch (e) {
//       print('Error updating password: $e');
//       return {
//         'status': false,
//         'message': 'Failed to update password',
//         'error': e.toString()
//       };
//     }
//   }

//   Future<Map<String, dynamic>?> uploadProfileImage({
//     required String userId,
//     required File imageFile,
//   }) async {
//     try {
//       final url = Uri.parse('${_baseUrl}profile/upload-image');
//       final token = LocalStorageService.instance.getToken();
      
//       final request = http.MultipartRequest('POST', url);
//       request.headers.addAll(_getHeaders(token: token));
//       request.fields['userId'] = userId;
//       request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

//       final streamedResponse = await request.send().timeout(_timeout);
//       final response = await http.Response.fromStream(streamedResponse);

//       return await _handleResponse(response);
//     } catch (e) {
//       print('Error uploading profile image: $e');
//       return {
//         'status': false,
//         'message': 'Failed to upload image',
//         'error': e.toString()
//       };
//     }
//   }
// }
