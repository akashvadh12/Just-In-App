
import 'package:flutter/material.dart';
class SosCheckInRequest {
  final String userId;
  final String status; // 'allOk', 'sos', 'ignored'
  final DateTime timestamp;
  final SosLocation? location;
  final String? deviceInfo;

  SosCheckInRequest({
    required this.userId,
    required this.status,
    required this.timestamp,
    this.location,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toJson(),
      'deviceInfo': deviceInfo,
    };
  }
}

class SosAlertRequest {
  final String userId;
  final String alertType; // 'SOS', 'MISSED_CHECKIN'
  final DateTime timestamp;
  final SosLocation? location;
  final String priority; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final int? missedCount;
  final String? lastCheckIn;
  final Map<String, dynamic>? additionalData;

  SosAlertRequest({
    required this.userId,
    required this.alertType,
    required this.timestamp,
    this.location,
    required this.priority,
    this.missedCount,
    this.lastCheckIn,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'alertType': alertType,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toJson(),
      'priority': priority,
      'missedCount': missedCount,
      'lastCheckIn': lastCheckIn,
      'additionalData': additionalData,
    };
  }
}

class SosConfigurationResponse {
  final int checkInIntervalMinutes;
  final int responseWindowMinutes;
  final bool isEnabled;
  final List<String> allowedStatuses;
  final SosNotificationSettings notificationSettings;

  SosConfigurationResponse({
    required this.checkInIntervalMinutes,
    required this.responseWindowMinutes,
    required this.isEnabled,
    required this.allowedStatuses,
    required this.notificationSettings,
  });

  factory SosConfigurationResponse.fromJson(Map<String, dynamic> json) {
    return SosConfigurationResponse(
      checkInIntervalMinutes: json['checkInIntervalMinutes'] ?? 30,
      responseWindowMinutes: json['responseWindowMinutes'] ?? 2,
      isEnabled: json['isEnabled'] ?? true,
      allowedStatuses: List<String>.from(json['allowedStatuses'] ?? ['allOk', 'sos']),
      notificationSettings: SosNotificationSettings.fromJson(
        json['notificationSettings'] ?? {},
      ),
    );
  }
}

class SosNotificationSettings {
  final bool emailEnabled;
  final bool smsEnabled;
  final bool pushEnabled;
  final List<String> adminEmails;
  final List<String> emergencyContacts;

  SosNotificationSettings({
    required this.emailEnabled,
    required this.smsEnabled,
    required this.pushEnabled,
    required this.adminEmails,
    required this.emergencyContacts,
  });

  factory SosNotificationSettings.fromJson(Map<String, dynamic> json) {
    return SosNotificationSettings(
      emailEnabled: json['emailEnabled'] ?? true,
      smsEnabled: json['smsEnabled'] ?? true,
      pushEnabled: json['pushEnabled'] ?? true,
      adminEmails: List<String>.from(json['adminEmails'] ?? []),
      emergencyContacts: List<String>.from(json['emergencyContacts'] ?? []),
    );
  }
}

class SosLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;

  SosLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'address': address,
    };
  }

  factory SosLocation.fromJson(Map<String, dynamic> json) {
    return SosLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble(),
      address: json['address'],
    );
  }
}

class SosCheckInResponse {
  final bool success;
  final String message;
  final DateTime? nextCheckInTime;
  final SosConfigurationResponse? updatedConfig;

  SosCheckInResponse({
    required this.success,
    required this.message,
    this.nextCheckInTime,
    this.updatedConfig,
  });

  factory SosCheckInResponse.fromJson(Map<String, dynamic> json) {
    return SosCheckInResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      nextCheckInTime: json['nextCheckInTime'] != null
          ? DateTime.parse(json['nextCheckInTime'])
          : null,
      updatedConfig: json['updatedConfig'] != null
          ? SosConfigurationResponse.fromJson(json['updatedConfig'])
          : null,
    );
  }
}

// File: lib/constants/sos_constants.dart
class SosConstants {
  // API Endpoints - Replace with your actual endpoints
  static const String baseUrl = 'https://your-api-domain.com/api';
  static const String checkInEndpoint = '/sos/check-in';
  static const String alertEndpoint = '/sos/alert';
  static const String configEndpoint = '/sos/config';
  static const String historyEndpoint = '/sos/history';
  
  // Default Configuration
  static const int defaultCheckInIntervalMinutes = 30;
  static const int defaultResponseWindowMinutes = 2;
  static const int maxCheckInIntervalMinutes = 120; // 2 hours
  static const int minCheckInIntervalMinutes = 5;   // 5 minutes
  static const int maxResponseWindowMinutes = 10;   // 10 minutes
  static const int minResponseWindowMinutes = 1;    // 1 minute
  
  // Status Types
  static const String statusAllOk = 'allOk';
  static const String statusSos = 'sos';
  static const String statusIgnored = 'ignored';
  static const String statusPending = 'pending';
  
  // Alert Types
  static const String alertTypeSos = 'SOS';
  static const String alertTypeMissedCheckIn = 'MISSED_CHECKIN';
  static const String alertTypeServiceStopped = 'SERVICE_STOPPED';
  
  // Priority Levels
  static const String priorityLow = 'LOW';
  static const String priorityMedium = 'MEDIUM';
  static const String priorityHigh = 'HIGH';
  static const String priorityCritical = 'CRITICAL';
  
  // Notification Messages
  static const String msgServiceStarted = 'SOS check-in service started';
  static const String msgServiceStopped = 'SOS check-in service stopped';
  static const String msgCheckInSuccess = 'Check-in recorded successfully';
  static const String msgSosAlertSent = 'Emergency SOS alert sent';
  static const String msgMissedCheckIn = 'Missed check-in - Alert sent to admin';
  static const String msgNetworkError = 'Network error - Check your connection';
  static const String msgServerError = 'Server error - Please try again';
}



class SosUtils {
  /// Get color based on SOS service status
  static Color getStatusColor(bool isActive, bool isPending) {
    if (isPending) return Colors.orange;
    if (isActive) return Colors.green;
    return Colors.grey;
  }
  
  /// Get status text based on service state
  static String getStatusText(bool isActive, bool isPending) {
    if (isPending) return 'Pending Response';
    if (isActive) return 'Active';
    return 'Inactive';
  }
  
  /// Get priority color
  static Color getPriorityColor(String priority) {
    switch (priority) {
      case SosConstants.priorityCritical:
        return Colors.red;
      case SosConstants.priorityHigh:
        return Colors.orange;
      case SosConstants.priorityMedium:
        return Colors.yellow[700]!;
      case SosConstants.priorityLow:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  /// Format duration in minutes to human readable string
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }
  
  /// Validate check-in interval
  static bool isValidInterval(int minutes) {
    return minutes >= SosConstants.minCheckInIntervalMinutes &&
           minutes <= SosConstants.maxCheckInIntervalMinutes;
  }
  
  /// Validate response window
  static bool isValidResponseWindow(int minutes) {
    return minutes >= SosConstants.minResponseWindowMinutes &&
           minutes <= SosConstants.maxResponseWindowMinutes;
  }
  
  /// Get next check-in time
  static DateTime getNextCheckInTime(int intervalMinutes) {
    return DateTime.now().add(Duration(minutes: intervalMinutes));
  }
  
  /// Check if user should have SOS service (not admin and clocked in)
  static bool shouldEnableSosService(bool isAdmin, String attendanceStatus) {
    return !isAdmin && attendanceStatus == 'In';
  }
}