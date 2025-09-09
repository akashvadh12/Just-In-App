import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For contentType
import 'package:path/path.dart';
import 'package:security_guard/core/api/api_client.dart';

class ApiService {
   final ApiClient _client = ApiClient();
  static const String resolveIssueEndpoint = 'IssuesRecord/resolve';
Future<bool> resolveIssue({
  required String token,
  required String issueId,
  required String userId,
  required double latitude,
  required double longitude,
  required String resolutionNote,
  required List<File> imageFiles,
}) async {
  try {
    // Prepare fields
    final fields = {
      'issueId': issueId,
      'userId': userId,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'resolutionNote': resolutionNote,
    };

    // Prepare files
    final files = <http.MultipartFile>[];
    for (File imageFile in imageFiles) {
      final fileName = basename(imageFile.path);
      files.add(
        await http.MultipartFile.fromPath(
          'images', // 👈 must match API field key
          imageFile.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    // Call client method
    final response = await _client.postMultipart(
      resolveIssueEndpoint,
      fields,
      files,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print("✅ Issue resolved successfully.");
      return true;
    } else {
      print("❌ Failed to resolve issue: ${response.statusCode} - ${response.body}");
      return false;
    }
  } catch (e) {
    print('❗ Exception in resolveIssue: $e');
    return false;
  }
}


}
