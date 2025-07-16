// Issues Controller with integrated API calls
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IssuesController extends GetxController
    with SingleGetTickerProviderMixin {
  // API Constants
  static const String BASE_URL = "https://justin.solarvision-cairo.com/api/";
  static const String UPSERT_INCIDENT_REPORT = 'Admin/UpsertIncidentReport';
  static const String ISSUES_RECORD = 'IssuesRecord';

  // Observable variables
  final RxList<Issue> _issues = <Issue>[].obs;
  final RxList<Issue> _resolvedIssues = <Issue>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt selectedTabIndex = 0.obs;

  // Getters
  List<Issue> get issues => _issues;
  List<Issue> get newIssues =>
      _issues.where((issue) => issue.status == IssueStatus.new_issue).toList();
  List<Issue> get resolvedIssues =>
      _resolvedIssues
          .where((issue) => issue.status == IssueStatus.resolved)
          .toList();

  int get newIssuesCount => newIssues.length;
  int get resolvedIssuesCount => resolvedIssues.length;

  // New pagination observables
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCount = 0.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;

  // ScrollController for pagination
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    fetchIssues();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        // Load more when user is 200px from bottom
        loadMoreIssues();
      }
    });
  }

  List<Issue> getIssuesByStatus(IssueStatus status) {
    if (status == IssueStatus.resolved) {
      return _resolvedIssues.where((issue) => issue.status == status).toList();
    }
    return _issues.where((issue) => issue.status == status).toList();
  }


  void updateIssue(Issue updatedIssue) {
    final index = _issues.indexWhere((issue) => issue.id == updatedIssue.id);
    if (index != -1) {
      _issues[index] = updatedIssue;
    }
  }

  Future<void> refreshIssues() async {
    currentPage.value = 1;
    hasMoreData.value = true;
    _issues.clear();
    await fetchIssues();
  }

  Future<void> loadMoreIssues() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      await fetchIssues(loadMore: true);
    }
  }

  // Updated fetch method with pagination
  Future<void> fetchIssues({
    String status = 'all',
    bool loadMore = false,
  }) async {
    final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return;
    }

    try {
      if (loadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final headers = await _getHeaders();
      final url = Uri.parse(
        '${BASE_URL}${ISSUES_RECORD}?status=$status&page=${currentPage.value}',
      );

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Update pagination info
        totalCount.value = jsonResponse['totalCount'] ?? 0;
        totalPages.value = jsonResponse['totalPages'] ?? 1;
        hasMoreData.value = currentPage.value < totalPages.value;

        // Parse issues from data array
        final List<dynamic> issuesData = jsonResponse['data'] ?? [];

        final List<Issue> newIssues =
            issuesData
                .cast<Map<String, dynamic>>()
                .map((json) => Issue.fromApiJson(json))
                .toList();

        if (loadMore) {
          // Add new issues to existing list

          if (status == "resolved") {
            _resolvedIssues.addAll(newIssues);
          } else {
            _issues.addAll(newIssues);
          }
         
        } else {
          // Replace existing issues
          if (status == "resolved") {
            _resolvedIssues.value = newIssues;
          } else{

          _issues.value = newIssues;
          }
        }
      } else {
        errorMessage.value =
            'Failed to load issues. Status: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Server error please try again later';
      print('Error fetching issues: $e');
    } finally {
      if (loadMore) {
        isLoadingMore.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  // Method to fetch specific status with pagination reset
  Future<void> fetchIssuesByStatus(String status) async {
    currentPage.value = 1;
    hasMoreData.value = true;
    // if (status == "resolved") {
    //   _resolvedIssues.clear();
    // } else {
    //   _issues.clear();
    // }
    await fetchIssues(status: status);
  }

  // Helper method to get headers (implement as needed)

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

  // // Fetch issues from API
  // Future<void> fetchIssues({String status = 'all'}) async {
  //   final connectivityController = Get.find<ConnectivityController>();

  //   if (connectivityController.isOffline.value) {
  //     connectivityController.showNoInternetSnackbar();
  //     return;
  //   }

  //   try {
  //     isLoading.value = true;
  //     errorMessage.value = '';

  //     final headers = await _getHeaders();
  //     final url = Uri.parse('${BASE_URL}${ISSUES_RECORD}?status=$status');

  //     final response = await http.get(url, headers: headers);

  //     if (response.statusCode == 200) {
  //       final List<dynamic> jsonData = json.decode(response.body);
  //       _issues.value =
  //           jsonData
  //               .cast<Map<String, dynamic>>()
  //               .map((json) => Issue.fromApiJson(json))
  //               .toList();
  //     } else {
  //       errorMessage.value =
  //           'Failed to load issues. Status: ${response.statusCode}';
  //     }
  //   } catch (e) {
  //     errorMessage.value = 'Server error please try again later';
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // // Refresh issues
  // Future<void> refreshIssues() async {
  //   await fetchIssues();
  // }

  // // Update issue locally
  // void updateIssue(Issue updatedIssue) {
  //   final index = _issues.indexWhere((issue) => issue.id == updatedIssue.id);
  //   if (index != -1) {
  //     _issues[index] = updatedIssue;
  //   }
  // }

  // Upsert incident report
  Future<void> upsertIncidentReport(Map<String, dynamic> data) async {
    final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return;
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

  // // Filter issues by status
  // List<Issue> getIssuesByStatus(IssueStatus status) {
  //   return _issues.where((issue) => issue.status == status).toList();
  // }
}
