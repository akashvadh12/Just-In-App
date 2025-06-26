

// patrol_history_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';


class PatrolHistoryItem {
  final String logID;
  final String userID;
  final String startLocationId;
  final DateTime startTime;
  final String endLocationId;
  final DateTime endTime;
  final bool status;
  final String? deviceId;
  final String remarks;
  final String? totalPoll;
  final String visitedPoll;
  final DateTime datetime;

  PatrolHistoryItem({
    required this.logID,
    required this.userID,
    required this.startLocationId,
    required this.startTime,
    required this.endLocationId,
    required this.endTime,
    required this.status,
    this.deviceId,
    required this.remarks,
    this.totalPoll,
    required this.visitedPoll,
    required this.datetime,
  });

  factory PatrolHistoryItem.fromJson(Map<String, dynamic> json) {
    return PatrolHistoryItem(
      logID: json['logID'] ?? '',
      userID: json['userID'] ?? '',
      startLocationId: json['startLocation_Id'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endLocationId: json['endLocation_Id'] ?? '',
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? false,
      deviceId: json['deviceId'],
      remarks: json['remarks'] ?? '',
      totalPoll: json['totalPoll'],
      visitedPoll: json['visitedPoll'] ?? '0',
      datetime: DateTime.parse(json['datetime']),
    );
  }
}

class PatrolHistoryDetail {
  final int serial;
  final String locationId;
  final String locationName;
  final double latitude;
  final double longitude;
  final String? selfie;
  final String? notes;
  final bool status;
  final String? visitTime;
  final List<String> images;

  PatrolHistoryDetail({
    required this.serial,
    required this.locationId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.selfie,
    this.notes,
    required this.status,
    this.visitTime,
    required this.images,
  });

  factory PatrolHistoryDetail.fromJson(Map<String, dynamic> json) {
    return PatrolHistoryDetail(
      serial: json['serial'] ?? 0,
      locationId: json['locationId'] ?? '',
      locationName: json['locationName'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      selfie: json['selfie'],
      notes: json['notes'],
      status: json['status'] ?? false,
      visitTime: json['visitTime'],
      images: List<String>.from(json['images'] ?? []),
    );
  }
}
class PatrolHistoryController extends GetxController {
  final RxList<PatrolHistoryItem> historyList = <PatrolHistoryItem>[].obs;
  final RxList<PatrolHistoryDetail> historyDetails = <PatrolHistoryDetail>[].obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isLoadingDetails = false.obs;
  final Rx<DateTime> startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> endDate = DateTime.now().obs;
  final ProfileController profileController = Get.find<ProfileController>();
  
  // Replace with actual user logic
  // final String userId = '202408056';
  
  static const String _baseUrl = 'https://official.solarvision-cairo.com/patrol';

  @override
  void onInit() {
    super.onInit();
    fetchPatrolHistory();
  }

  Future<void> fetchPatrolHistory() async {
        final connectivityController = Get.find<ConnectivityController>();

    if (connectivityController.isOffline.value) {
      connectivityController.showNoInternetSnackbar();
      return ;
    }
    try {
      isLoadingHistory.value = true;
      
      final startDateStr = '${startDate.value.year}%2F${startDate.value.month.toString().padLeft(2, '0')}%2F${startDate.value.day.toString().padLeft(2, '0')}';
      final endDateStr = '${endDate.value.year}%2F${endDate.value.month.toString().padLeft(2, '0')}%2F${endDate.value.day.toString().padLeft(2, '0')}';
      
       
      final userId = profileController.userModel.value?.userId ?? '';
      final url = '$_baseUrl/Userhistory?start=$startDateStr&end=$endDateStr&UserId=$userId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<PatrolHistoryItem> history = jsonData
            .map((json) => PatrolHistoryItem.fromJson(json))
            .toList();
        
        historyList.clear();
        historyList.addAll(history);
        
        if (history.isEmpty) {
          Get.snackbar(
            'No Data',
            'No patrol history found for the selected date range',
            backgroundColor: AppColors.greyColor,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        throw Exception('Failed to load patrol history: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load patrol history: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      print('Error fetching patrol history: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> fetchHistoryDetails(String logID) async {
    try {
      isLoadingDetails.value = true;
      
      final url = '$_baseUrl/history?logId=$logID';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<PatrolHistoryDetail> details = jsonData
            .map((json) => PatrolHistoryDetail.fromJson(json))
            .toList();
        
        historyDetails.clear();
        historyDetails.addAll(details);
      } else {
        throw Exception('Failed to load history details: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load history details: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      print('Error fetching history details: $e');
    } finally {
      isLoadingDetails.value = false;
    }
  }

  Future<void> selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate.value, end: endDate.value),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      startDate.value = picked.start;
      endDate.value = picked.end;
      await fetchPatrolHistory();
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }
}