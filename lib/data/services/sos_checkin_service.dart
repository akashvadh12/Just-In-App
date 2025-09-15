// File: lib/services/sos_check_in_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/api/api_constants.dart';
import 'package:security_guard/data/services/api_get_service.dart';
import 'package:security_guard/data/services/background_sos_foreground_service.dart';
import 'package:security_guard/data/services/background_sos_service.dart';
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

  // Configuration - these would normally come from API
  final RxInt checkInIntervalMinutes = 1.obs;
  final RxInt responseWindowMinutes = 1.obs;
  final RxBool isServiceActive = false.obs;
  final RxBool isCheckInPending = false.obs;
  final RxString lastCheckInTime = ''.obs;
  final RxInt missedCheckIns = 0.obs;
  final RxBool isSubmittingCheckIn = false.obs;

  Timer? _checkInTimer;
  Timer? _responseTimer;
  DateTime? _lastCheckInSent;
  DateTime? _currentPromptTime;

  static const String _logTag = '[SosCheckInService]';

  // Queue for offline check-ins
  final List<Map<String, dynamic>> _pendingCheckIns = [];

  @override
  void onInit() {
    super.onInit();
    _loadConfiguration();
    _setupConnectivityListener();
  }

  @override
  void onClose() {
    stopService();
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

Future<void> startBackgroundService() async {
  await BackgroundSosForegroundService.startBackgroundSosService(
    userId: await _getUserId(),
    companyId: profileController.userModel.value?.companyId ?? '',
    siteId: profileController.userModel.value?.siteId ?? '',
    intervalMinutes: checkInIntervalMinutes.value,
    responseWindowMinutes: responseWindowMinutes.value,
    apiBaseUrl: BASE_URL,
  );
}

  /// Stop background SOS service
Future<void> stopBackgroundService() async {
  await BackgroundSosForegroundService.stopBackgroundSosService();
}

  /// Start the SOS check-in service
  void startService() {
    if (isServiceActive.value) return;

    isServiceActive.value = true;
    _scheduleNextCheckIn();
    startBackgroundService();

    Get.snackbar(
      'SOS Service Started',
      'Periodic safety check-ins are now active',
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      icon: const Icon(Icons.security, color: Colors.white),
      duration: const Duration(seconds: 2),
    );

    dev.log('$_logTag SOS Check-in service started');
  }

  /// Stop the SOS check-in service
  void stopService() {
    isServiceActive.value = false;
    _checkInTimer?.cancel();
    _responseTimer?.cancel();
    isCheckInPending.value = false;

    stopBackgroundService();
    Get.snackbar(
      'SOS Service Stopped',
      'Periodic safety check-ins have been disabled',
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
      icon: const Icon(Icons.security_outlined, color: Colors.white),
      duration: const Duration(seconds: 3),
    );

    dev.log('$_logTag SOS Check-in service stopped');
  }

  /// Load configuration from API
  Future<void> _loadConfiguration() async {
    try {
      if (connectivityController.isOffline.value) {
        dev.log('$_logTag Using default configuration (offline)');
        return;
      }

      // You can load these from API or settings
      checkInIntervalMinutes.value = 1;
      responseWindowMinutes.value = 1;

      dev.log(
        '$_logTag Configuration loaded: CheckIn=${checkInIntervalMinutes.value}min, Response=${responseWindowMinutes.value}min',
      );
    } catch (e) {
      dev.log('$_logTag Error loading SOS configuration: $e');
      // Continue with default values
    }
  }

  /// Schedule the next check-in
  void _scheduleNextCheckIn() {
    if (!isServiceActive.value) return;

    _checkInTimer?.cancel();
    _checkInTimer = Timer(
      Duration(minutes: checkInIntervalMinutes.value),
      _showCheckInDialog,
    );

    final nextTime = DateTime.now().add(
      Duration(minutes: checkInIntervalMinutes.value),
    );
    dev.log(
      '$_logTag Next SOS check-in scheduled for: ${_formatDateTime(nextTime)}',
    );
  }

  /// Show the check-in dialog
  void _showCheckInDialog() {
    if (!isServiceActive.value) return;

    isCheckInPending.value = true;
    _lastCheckInSent = DateTime.now();
    _currentPromptTime = DateTime.now(); // Store the prompt time

    dev.log('$_logTag Showing SOS check-in dialog');

    // Start response timer
    _responseTimer = Timer(
      Duration(minutes: responseWindowMinutes.value),
      _handleNoResponse,
    );

    Get.dialog(
      const SosCheckInDialog(),
      barrierDismissible: false,
      name: 'SosCheckInDialog',
    );
  }
/// Handle user response to check-in
Future<void> handleCheckInResponse(CheckInStatus status) async {
  dev.log('$_logTag SOS Check-in response: ${status.toString()}');

  _responseTimer?.cancel();
  isCheckInPending.value = false;

  // **MOVED: Close dialog immediately for better UX**
  Get.back();

  // **MOVED: Show immediate feedback**
  _showImmediateFeedback(status);

  try {
    // Send check-in response to API
    await _sendCheckInResponse(status);

    if (status == CheckInStatus.allOk) {
      lastCheckInTime.value = _formatDateTime(DateTime.now());
      missedCheckIns.value = 0;
      _scheduleNextCheckIn();

      // Update to success message
      Get.snackbar(
        '✅ Check-in Successful',
        'Thank you for confirming your safety',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } else if (status == CheckInStatus.sos) {
      _handleSosAlert();
    } else if (status == CheckInStatus.ignore) {
      _scheduleNextCheckIn(); // Continue with normal schedule
    }
  } catch (e) {
    dev.log('$_logTag Error handling check-in response: $e');
    Get.snackbar(
      'Check-in Error',
      'Failed to send response. It will be sent when connection is restored.',
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
      icon: const Icon(Icons.cloud_off, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}

// **NEW: Add this method**
void _showImmediateFeedback(CheckInStatus status) {
  switch (status) {
    case CheckInStatus.allOk:
      Get.snackbar(
        '✅ Processing',
        'Recording your safety status...',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
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
        icon: const Icon(Icons.emergency, color: Colors.white),
        duration: const Duration(seconds: 1),
      );
      break;
    case CheckInStatus.ignore:
      Get.snackbar(
        'Check-in Dismissed',
        'Next check-in scheduled.',
        backgroundColor: Colors.grey.withOpacity(0.8),
        colorText: Colors.white,
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
    missedCheckIns.value++;

    Get.back(); // Close dialog if still open

    // Send missed check-in
    _sendMissedCheckInResponse();
    _scheduleNextCheckIn();

    Get.snackbar(
      '⚠️ Missed Check-in',
      'No response received. Alert sent to admin.',
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  /// Send check-in response to API
  Future<void> _sendCheckInResponse(CheckInStatus status) async {
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
      'promptTime': (_currentPromptTime ?? DateTime.now()).toIso8601String(),
      'response': _getApiResponseString(status),
      'companyID': userModel.companyId ?? '',
      'siteId': userModel.siteId ?? '',
    };

    dev.log('$_logTag Sending check-in response: ${checkInData['response']}');

    if (connectivityController.isOffline.value) {
      // Queue for later
      _pendingCheckIns.add(checkInData);
      dev.log('$_logTag Check-in queued for later (offline)');
      return;
    }

    await _sendCheckInToApi(checkInData);
  }

  /// Send missed check-in response
  Future<void> _sendMissedCheckInResponse() async {
    try {
      await _sendCheckInResponse(CheckInStatus.pending);
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
        return 'Missed'; // or 'NoResponse'
    }
  }

  /// Send SOS alert
  void _handleSosAlert() {
    Get.back(); // Close dialog
    _scheduleNextCheckIn();
    Get.snackbar(
      '🆘 SOS Alert Sent',
      'Emergency alert has been sent to admin and authorities',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.emergency, color: Colors.white),
      duration: const Duration(seconds: 5),
    );

    // Don't schedule next check-in for SOS - let admin handle
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

  /// Update configuration
  void updateConfiguration({int? intervalMinutes, int? responseMinutes}) {
    bool needsRestart = false;

    if (intervalMinutes != null &&
        intervalMinutes != checkInIntervalMinutes.value) {
      checkInIntervalMinutes.value = intervalMinutes;
      needsRestart = true;
      dev.log('$_logTag Updated check-in interval to $intervalMinutes minutes');
    }

    if (responseMinutes != null &&
        responseMinutes != responseWindowMinutes.value) {
      responseWindowMinutes.value = responseMinutes;
      dev.log('$_logTag Updated response window to $responseMinutes minutes');
    }

    // Restart service with new configuration
    if (needsRestart && isServiceActive.value) {
      dev.log('$_logTag Restarting SOS service with new configuration');
      stopService();
      startService();
    }
  }

  /// Get service status summary
  Map<String, dynamic> getServiceStatus() {
    return {
      'isActive': isServiceActive.value,
      'isPending': isCheckInPending.value,
      'isSubmitting': isSubmittingCheckIn.value,
      'checkInInterval': checkInIntervalMinutes.value,
      'responseWindow': responseWindowMinutes.value,
      'lastCheckIn': lastCheckInTime.value,
      'missedCount': missedCheckIns.value,
      'pendingCount': _pendingCheckIns.length,
      'nextCheckIn':
          isServiceActive.value
              ? DateTime.now()
                  .add(Duration(minutes: checkInIntervalMinutes.value))
                  .toIso8601String()
              : null,
    };
  }

  /// Force sync pending check-ins (for manual sync)
  Future<void> forceSyncPendingCheckIns() async {
    if (_pendingCheckIns.isEmpty) {
      Get.snackbar(
        'No Pending Check-ins',
        'All check-ins are already synced',
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (connectivityController.isOffline.value) {
      Get.snackbar(
        'No Internet Connection',
        'Please check your internet connection and try again',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    await _processPendingCheckIns();
  }
}
