import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For contentType
import 'package:path/path.dart'; // For basename

class ApiService {
  static const String baseUrl = "https://justin.solarvision-cairo.com/api/";
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
      final url = Uri.parse('$baseUrl$resolveIssueEndpoint');

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add regular fields
      request.fields['issueId'] = issueId;
      request.fields['userId'] = userId;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['resolutionNote'] = resolutionNote;

      // Add image files
      for (File imageFile in imageFiles) {
        final fileName = basename(imageFile.path);
        final mimeType = 'image/jpeg'; // Or detect with lookupMimeType()

        request.files.add(
          await http.MultipartFile.fromPath(
            'images', // This must match your API's expected key
            imageFile.path,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
