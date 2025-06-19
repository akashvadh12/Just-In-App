import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryController extends GetxController {
  // Observable variables
  var attendanceRecords = <AttendanceRecord>[].obs;
  var isLoading = false.obs;
  var currentMonth = DateTime.now().obs;
  var selectedTab = 0.obs; // 0: History, 1: Today, 2: Report
  var todayAttendance = Rx<TodayAttendance?>(null);
  var reportRecords = <AttendanceRecord>[].obs;
  var fromDate = DateTime.now().obs;
  var toDate = DateTime.now().obs;
  final ProfileController profileController = Get.find<ProfileController>();

  // Base URL
  final String baseUrl =
      "https://official.solarvision-cairo.com/api/AttendanceRecord";

  @override
  void onInit() {
    super.onInit();
    fetchAttendanceHistory();
    fetchTodayAttendance();
  }

  // Get userId from SharedPreferences
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id'); // ✅ match saved key
    if (userId == null || userId.isEmpty) {
      print('⚠️ User ID not found or empty in SharedPreferences.');
    } else {
      print('✅ Retrieved User ID: $userId');
    }
    return userId;
  }

  // Get auth token from SharedPreferences
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('authToken');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Show error message
  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  // Show success message
  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  // Fetch attendance history
  Future<void> fetchAttendanceHistory() async {
    try {
      isLoading.value = true;

      final userId = profileController.userModel.value?.userId;
      final authToken = await getAuthToken();

      if (userId == null || userId.isEmpty) {
        _showError(
          "Authentication Error",
          "User ID not found. Please login again",
        );
        return;
      }

      final monthStr = DateFormat('yyyy-MM').format(currentMonth.value);
      final url = '$baseUrl/attendance/history?userId=$userId&month=$monthStr';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final today = DateTime.now();

        final filteredRecords =
            data
                .map((json) => AttendanceRecord.fromJson(json))
                .where((record) {
                  // Parse the date from the record
                  final recordDate = DateTime.tryParse(record.date);
                  if (recordDate == null) return false;

                  // Keep only records that are on or before today
                  return recordDate.isBefore(
                    today.add(Duration(days: 0)),
                  ); // inclusive of today
                })
                .toList()
                .reversed
                .toList();
        ;

        attendanceRecords.value = filteredRecords;
      } else if (response.statusCode == 500) {
        Get.snackbar(
          "Server Error",
          "Internal server error. Please try again later.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else {
        _showError("Error", "Failed to load attendance history");
      }
    } catch (e) {
      _showError("Network Error", "Please check your internet connection");
      print('Error fetching attendance history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch today's attendance
  Future<void> fetchTodayAttendance() async {
    try {
      isLoading.value = true;

      final userId = profileController.userModel.value?.userId;
      final authToken = await getAuthToken();

      if (userId == null || userId.isEmpty) {
        // _showError(
        //   "Authentication Error",
        //   "User ID not found. Please login again",
        // );
        return;
      }

      final url = '$baseUrl/attendance/today/$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        todayAttendance.value = TodayAttendance.fromJson(data);
        // _showSuccess("Success", "Today's attendance loaded successfully");
      } else {
        _showError("Error", "Failed to load today's attendance");
      }
    } catch (e) {
      _showError("Network Error", "Please check your internet connection");
      print('Error fetching today attendance: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch attendance report
  Future<void> fetchAttendanceReport() async {
    try {
      isLoading.value = true;

      final userId = profileController.userModel.value?.userId;
      final authToken = await getAuthToken();
      print("the user id is🔴🔴🔴 : $userId and authtoken $authToken");

      if (userId == null || userId.isEmpty) {
        _showError(
          "Authentication Error",
          "User ID not found. Please login again",
        );
        return;
      }

      final fromDateStr = DateFormat('yyyy-MM-dd').format(fromDate.value);
      final toDateStr = DateFormat('yyyy-MM-dd').format(toDate.value);

      final url =
          '$baseUrl/attendance/report?userId=$userId&fromDate=$fromDateStr&toDate=$toDateStr';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        reportRecords.value =
            data.map((json) => AttendanceRecord.fromJson(json)).toList();

        _showSuccess("Success", "Attendance report loaded successfully");
      } else {
        _showError("Error", "Failed to load attendance report");
      }
    } catch (e) {
      _showError("Network Error", "Please check your internet connection");
      print('Error fetching attendance report: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Change month
  void changeMonth(bool isNext) {
    if (isNext) {
      currentMonth.value = DateTime(
        currentMonth.value.year,
        currentMonth.value.month + 1,
        1,
      );
    } else {
      currentMonth.value = DateTime(
        currentMonth.value.year,
        currentMonth.value.month - 1,
        1,
      );
    }
    fetchAttendanceHistory();
  }

  // Change tab
  void changeTab(int index) {
    selectedTab.value = index;
    switch (index) {
      case 0:
        fetchAttendanceHistory();
        break;
      case 1:
        fetchTodayAttendance();
        break;
      case 2:
        fetchAttendanceReport();
        break;
    }
  }

  // Set date range for reports
  void setDateRange(DateTime from, DateTime to) {
    fromDate.value = from;
    toDate.value = to;
    fetchAttendanceReport();
  }

  // Refresh current data
  Future<void> refreshData() async {
    switch (selectedTab.value) {
      case 0:
        await fetchAttendanceHistory();
        break;
      case 1:
        await fetchTodayAttendance();
        break;
      case 2:
        await fetchAttendanceReport();
        break;
    }
  }
}

// Data Models
class AttendanceRecord {
  final String date;
  final String? inTime;
  final String? outTime;
  final String? inPhoto;
  final String? outPhoto;
  final String? duration;
  final Location? inLocation;
  final Location? outLocation;
  final String status;

  AttendanceRecord({
    required this.date,
    this.inTime,
    this.outTime,
    this.inPhoto,
    this.outPhoto,
    this.duration,
    this.inLocation,
    this.outLocation,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] ?? '',
      inTime: json['inTime'],
      outTime: json['outTime'],
      inPhoto: json['inPhoto'],
      outPhoto: json['outPhoto'],
      duration: json['duration'],
      inLocation:
          json['inLocation'] != null
              ? Location.fromJson(json['inLocation'])
              : null,
      outLocation:
          json['outLocation'] != null
              ? Location.fromJson(json['outLocation'])
              : null,
      status: json['status'] ?? 'Unknown',
    );
  }
}

class TodayAttendance {
  final String? checkInTime;
  final String? checkOutTime;
  final List<AttendanceRecordDetail> records;

  TodayAttendance({this.checkInTime, this.checkOutTime, required this.records});

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    return TodayAttendance(
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      records:
          (json['records'] as List<dynamic>?)
              ?.map((record) => AttendanceRecordDetail.fromJson(record))
              .toList() ??
          [],
    );
  }
}

class AttendanceRecordDetail {
  final int id;
  final String userId;
  final String type;
  final String latitude;
  final String longitude;
  final String selfieUrl;
  final String timestamp;

  AttendanceRecordDetail({
    required this.id,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.selfieUrl,
    required this.timestamp,
  });

  factory AttendanceRecordDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordDetail(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      selfieUrl: json['selfieUrl'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class Location {
  final String lat;
  final String lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(lat: json['lat'] ?? '', lng: json['lng'] ?? '');
  }
}
