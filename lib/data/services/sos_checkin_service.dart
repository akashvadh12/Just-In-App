// File: lib/services/sos_check_in_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';
import 'package:security_guard/data/services/conectivity_controller.dart';
import 'package:security_guard/modules/profile/controller/localStorageService/localStorageService.dart';
import 'dart:developer' as dev;

import 'package:security_guard/shared/widgets/sos_checkIn_dialog.dart';

enum CheckInStatus { allOk, sos, ignore, pending }

class SosCheckInService extends GetxController {
  static SosCheckInService get instance => Get.find<SosCheckInService>();

  final ProfileController profileController = Get.find<ProfileController>();
  final ConnectivityController connectivityController =
      Get.find<ConnectivityController>();
  final LocalStorageService _storage = LocalStorageService.instance;
  final ApiGetServices _apiService = Get.find<ApiGetServices>();

  final RxInt responseWindowMinutes = 1.obs;
  final RxBool isCheckInPending = false.obs;
  final RxString lastCheckInTime = ''.obs;
  final RxBool isSubmittingCheckIn = false.obs;

  Timer? _responseTimer;
  DateTime? _currentPromptTime;
  String? _currentCheckInId; // Track current check-in ID

  static const String _logTag = '[SosCheckInService]';

  // Queue for offline check-ins
  final List<Map<String, dynamic>> _pendingCheckIns = [];

  @override
  void onInit() {
    super.onInit();
    _setupConnectivityListener();
  }

  @override
  void onClose() {
    _responseTimer?.cancel();
    super.onClose();
  }

  /// Setup connectivity listener to process pending check-ins when online
  void _setupConnectivityListener() {
    ever(connectivityController.isOffline, (bool isOffline) {
      if (!isOffline && _pendingCheckIns.isNotEmpty) {
        _processPendingCheckIns();
      }
    });
  }

  /// Process pending check-ins when connection is restored
  Future<void> _processPendingCheckIns() async {
    if (_pendingCheckIns.isEmpty) return;

    dev.log('$_logTag Processing ${_pendingCheckIns.length} pending check-ins');

    final checkInsToProcess = List<Map<String, dynamic>>.from(_pendingCheckIns);
    _pendingCheckIns.clear();

    for (final checkInData in checkInsToProcess) {
      try {
        await _sendCheckInToApi(checkInData);
        dev.log(
          '$_logTag Successfully sent pending check-in: ${checkInData['response']}',
        );
      } catch (e) {
        dev.log('$_logTag Failed to send pending check-in: $e');
        // Re-queue if still fails
        _pendingCheckIns.add(checkInData);
      }
    }

    if (_pendingCheckIns.isEmpty) {
      Get.snackbar(
        'Check-ins Synced',
        'All pending safety check-ins have been sent',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.cloud_done, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Handle check-in triggered by notification
  // Future<void> handleNotificationCheckIn(String checkInId) async {
  //   dev.log('$_logTag Handling notification-triggered check-in: $checkInId');
    
  //   // Close any existing dialog first
  //   if (Get.isDialogOpen ?? false) {
  //     Get.back();
  //   }

  //   isCheckInPending.value = true;
  //   _currentPromptTime = DateTime.now();
  //   _currentCheckInId = checkInId;

  //   dev.log('$_logTag Showing SOS check-in dialog (ID: $checkInId)');

  //   // Start response timer
  //   _responseTimer?.cancel();
  //   _responseTimer = Timer(
  //     Duration(minutes: responseWindowMinutes.value),
  //     _handleNoResponse,
  //   );

  //   Get.dialog(
  //     SosCheckInDialog(checkInId: checkInId),
  //     barrierDismissible: false,
  //     name: 'SosCheckInDialog',
  //   );
  // }

  /// Handle user response to check-in
  Future<void> handleCheckInResponse(CheckInStatus status, {String? checkInId}) async {
    dev.log('$_logTag SOS Check-in response: ${status.toString()}, ID: $checkInId');

    _responseTimer?.cancel();
    isCheckInPending.value = false;
    
    // Use the stored checkInId if none provided
    final effectiveCheckInId = checkInId ?? _currentCheckInId;
    _currentCheckInId = null; // Clear after use

    // Show immediate feedback
    _showImmediateFeedback(status);

    try {
      // Send check-in response to API
      await _sendCheckInResponse(status, checkInId: effectiveCheckInId);

      if (status == CheckInStatus.allOk) {
        lastCheckInTime.value = _formatDateTime(DateTime.now());

        // Update to success message
        // Get.snackbar(
        //   '✅ Check-in Successful',
        //   'Thank you for confirming your safety',
        //   backgroundColor: Colors.green.withOpacity(0.8),
        //   colorText: Colors.white,
        //    snackPosition: SnackPosition.BOTTOM,
        //   icon: const Icon(Icons.check_circle, color: Colors.white),
        //   duration: const Duration(seconds: 2),
        // );
      } else if (status == CheckInStatus.sos) {
        _handleSosAlert(effectiveCheckInId);
      }
    } catch (e) {
      dev.log('$_logTag Error handling check-in response: $e');
      Get.snackbar(
        'Check-in Error',
        'Failed to send response. It will be sent when connection is restored.',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
         snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.cloud_off, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Show immediate feedback to user
  void _showImmediateFeedback(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.allOk:
        Get.snackbar(
          '✅ Processing',
          'Recording your safety status...',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
           snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 1),
        );
        break;
      case CheckInStatus.sos:
        Get.snackbar(
          '🚨 Emergency Alert',
          'Sending emergency alert...',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
           snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.emergency, color: Colors.white),
          duration: const Duration(seconds: 1),
        );
        break;
      case CheckInStatus.ignore:
        Get.snackbar(
          'Check-in Dismissed',
          'Response recorded.',
          backgroundColor: Colors.grey.withOpacity(0.8),
          colorText: Colors.white,
           snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
        break;
      case CheckInStatus.pending:
        // No feedback needed for pending status
        break;
    }
  }

  /// Handle no response within time window
  void _handleNoResponse() {
    if (!isCheckInPending.value) return;

    dev.log('$_logTag SOS Check-in timeout - no response received');

    isCheckInPending.value = false;
    final missedCheckInId = _currentCheckInId;
    _currentCheckInId = null;

    if (Get.isDialogOpen ?? false) {
      Get.back(); // Close dialog if still open
    }

    // Send missed check-in
    _sendMissedCheckInResponse(checkInId: missedCheckInId);

    Get.snackbar(
      '⚠️ Missed Check-in',
      'No response received. Alert sent to admin.',
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
       snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }


//   Future<void> _sendCheckInResponse(CheckInStatus status, {String? checkInId}) async {
//   final userModel = profileController.userModel.value;
//   if (userModel == null) {
//     dev.log('$_logTag User model is null, cannot send check-in');
//     throw Exception('User information not available');
//   }

//   // Get current location using flutter_background_geolocation
//   bg.Location? location;
//   try {
//     location = await bg.BackgroundGeolocation.getCurrentPosition(
//       timeout: 10, // 10 seconds
//       maximumAge: 5000, // Accept location up to 5 seconds old
//       desiredAccuracy: 10, // 10 meters accuracy
//       samples: 1,
//     );
//   } catch (e) {
//     dev.log('$_logTag Error getting location for check-in: $e');
//     // Continue without location (will use 0,0)
//   }

//   final checkInData = {
//     'userId': userModel.userId ?? '',
//     'latitude': location?.coords.latitude ?? 0.0,
//     'longitude': location?.coords.longitude ?? 0.0,
//     'response': _getApiResponseString(status),
//     if (checkInId != null) 'checkInId': checkInId,
//   };

//   dev.log('$_logTag Sending check-in response: ${checkInData['response']} (ID: $checkInId)');

//   if (connectivityController.isOffline.value) {
//     // Queue for later
//     _pendingCheckIns.add(checkInData);
//     dev.log('$_logTag Check-in queued for later (offline)');
//     return;
//   }

//   await _sendCheckInToApi(checkInData);
// }

//   /// Send missed check-in response
//   Future<void> _sendMissedCheckInResponse({String? checkInId}) async {
//     try {
//       await _sendCheckInResponse(CheckInStatus.pending, checkInId: checkInId);
//     } catch (e) {
//       dev.log('$_logTag Error sending missed check-in: $e');
//     }
//   }

  /// Send check-in response to API
  Future<void> _sendCheckInResponse(CheckInStatus status, {String? checkInId}) async {
    final userModel = profileController.userModel.value;
    if (userModel == null) {
      dev.log('$_logTag User model is null, cannot send check-in');
      throw Exception('User information not available');
    }

    // Get current location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      dev.log('$_logTag Error getting location for check-in: $e');
      // Continue without location (will use 0,0)
    }

    final checkInData = {
      'userId': userModel.userId ?? '',
      'latitude': position?.latitude ?? 0.0,
      'longitude': position?.longitude ?? 0.0,
      'response': _getApiResponseString(status),
      if (checkInId != null) 'checkInId': checkInId,
    };

    dev.log('$_logTag Sending check-in response: ${checkInData['response']} (ID: $checkInId)');

    if (connectivityController.isOffline.value) {
      // Queue for later
      _pendingCheckIns.add(checkInData);
      dev.log('$_logTag Check-in queued for later (offline)');
      return;
    }

    await _sendCheckInToApi(checkInData);
  }

  /// Send missed check-in response
  Future<void> _sendMissedCheckInResponse({String? checkInId}) async {
    try {
      await _sendCheckInResponse(CheckInStatus.pending, checkInId: checkInId);
    } catch (e) {
      dev.log('$_logTag Error sending missed check-in: $e');
    }
  }

  /// Send check-in data to API
  Future<void> _sendCheckInToApi(Map<String, dynamic> checkInData) async {
    try {
      isSubmittingCheckIn.value = true;

      final response = await _apiService.sendSafetyCheckIn(checkInData);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          dev.log(
            '$_logTag Check-in sent successfully. ID: ${responseData['id']}',
          );
        } else {
          throw Exception(
            'Server returned false status: ${responseData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } finally {
      isSubmittingCheckIn.value = false;
    }
  }

  /// Convert CheckInStatus to API response string
  String _getApiResponseString(CheckInStatus status) {
    switch (status) {
      case CheckInStatus.allOk:
        return 'AllOK';
      case CheckInStatus.sos:
        return 'SOS';
      case CheckInStatus.ignore:
        return 'Ignore';
      case CheckInStatus.pending:
        return 'Missed';
    }
  }

  /// Send SOS alert
  void _handleSosAlert([String? checkInId]) {
    if (Get.isDialogOpen ?? false) {
      Get.back(); // Close dialog
    }
    
    // Get.snackbar(
    //   '🆘 SOS Alert Sent',
    //   'Emergency alert has been sent to admin and authorities',
    //   backgroundColor: Colors.red,
    //   colorText: Colors.white,
    //    snackPosition: SnackPosition.BOTTOM,
      
    //   icon: const Icon(Icons.emergency, color: Colors.white),
    //   duration: const Duration(seconds: 2),
    // );

    dev.log('$_logTag SOS alert handled (ID: $checkInId)');
  }

  /// Check if there's currently a pending check-in dialog
  bool get hasActiveDialog => isCheckInPending.value;

  /// Force close any active check-in dialog
  void forceCloseDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    _responseTimer?.cancel();
    isCheckInPending.value = false;
    _currentCheckInId = null;
    dev.log('$_logTag Force closed check-in dialog');
  }

  /// Helper methods
  Future<String> _getUserId() async {
    String? userId = await _storage.getUserId();
    if (userId == null || userId.isEmpty) {
      userId = profileController.userModel.value?.userId ?? '';
    }
    return userId;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}