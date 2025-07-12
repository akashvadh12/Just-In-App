
// Issues Controller with integrated API calls
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssuesController extends GetxController with SingleGetTickerProviderMixin {
  // API Constants
  static const String BASE_URL = "https://justin.solarvision-cairo.com/api/";
  static const String UPSERT_INCIDENT_REPORT = 'Admin/UpsertIncidentReport';
  static const String ISSUES_RECORD = 'IssuesRecord';
  
  // Observable variables
  final RxList<Issue> _issues = <Issue>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt selectedTabIndex = 0.obs;
  
  // Getters
  List<Issue> get issues => _issues;
  List<Issue> get newIssues => _issues.where((issue) => issue.status == IssueStatus.new_issue).toList();
  List<Issue> get resolvedIssues => _issues.where((issue) => issue.status == IssueStatus.resolved).toList();
  
  int get newIssuesCount => newIssues.length;
  int get resolvedIssuesCount => resolvedIssues.length;

  @override
  void onInit() {
    super.onInit();
    fetchIssues();
  }

  // Auth token helper
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print("Retrieved Auth Token: 😁😁👍 ${token ?? 'No token found'}");
      return token;
    } catch (e) {
      print("Error retrieving auth token: $e");
      return null;
    }
  }

  // Headers helper
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch issues from API
  Future<void> fetchIssues({String status = 'all'}) async {

        final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return ;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final headers = await _getHeaders();
      final url = Uri.parse('${BASE_URL}${ISSUES_RECORD}?status=$status');
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        _issues.value = jsonData
            .cast<Map<String, dynamic>>()
            .map((json) => Issue.fromApiJson(json))
            .toList();
      } else {
        errorMessage.value = 'Failed to load issues. Status: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Server error please try again later';
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh issues
  Future<void> refreshIssues() async {
    await fetchIssues();
  }

  // Update issue locally
  void updateIssue(Issue updatedIssue) {
    final index = _issues.indexWhere((issue) => issue.id == updatedIssue.id);
    if (index != -1) {
      _issues[index] = updatedIssue;
    }
  }

  // Upsert incident report
  Future<void> upsertIncidentReport(Map<String, dynamic> data) async {
        final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return ;
    }
    try {
      isLoading.value = true;
      
      final headers = await _getHeaders();
      final url = Uri.parse('$BASE_URL$UPSERT_INCIDENT_REPORT');
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh issues after successful update
        await fetchIssues();
         Get.snackbar(
          "Success",
          "Incident report updated successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
        );
       
      } else {
         Get.snackbar(
          "Error",
          "Failed to update incident. Status: ${response.statusCode}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
        );
      
      }
    } catch (e) {

         Get.snackbar(
          "Error",
          "Network error: $e",
          backgroundColor: Colors.red,
          colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
        );
     ;
    } finally {
      isLoading.value = false;
    }
  }

  // Tab management
  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  // Filter issues by status
  List<Issue> getIssuesByStatus(IssueStatus status) {
    return _issues.where((issue) => issue.status == status).toList();
  }
}