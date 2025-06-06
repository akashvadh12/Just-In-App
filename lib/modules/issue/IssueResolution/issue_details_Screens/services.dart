// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiService {
//   static const String baseUrl = "https://official.solarvision-cairo.com/api/";
//   static const String resolveIssueEndpoint = 'IssuesRecord/resolve';

//   Future<bool> resolveIssue({
//     required String token,
//     required String issueId,
//     required String userId,
//     required double latitude,
//     required double longitude,
//     required String resolutionNote,
//     required List<String> images,
//   }) async {
//     try {
//       final url = Uri.parse('$baseUrl$resolveIssueEndpoint');
      
//       final headers = {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       };

//       final body = jsonEncode({
//         'issueId': issueId,
//         'userId': userId,
//         'latitude': latitude,
//         'longitude': longitude,
//         'resolutionNote': resolutionNote,
//         'images': images,
//       });

//       final response = await http.post(
//         url,
//         headers: headers,
//         body: body,
//       );

//       if (response.statusCode == 200) {
//         return true;
//       } else {
//         print('Failed to resolve issue: ${response.statusCode} - ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       print('Exception in resolveIssue: $e');
//       return false;
//     }
//   }
// }