import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';

class IssueService {
  static const String baseUrl =
      'https://official.solarvision-cairo.com/api/IssuesRecord?status=all'; // Replace with your API URL

  Future<List<Issue>> fetchIssues() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print(response.body);
      return data.map((json) => Issue.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load issues');
    }
  }
}
