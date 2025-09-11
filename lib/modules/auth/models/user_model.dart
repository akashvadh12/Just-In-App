// ==================== UPDATED USER MODEL ====================
import 'dart:convert';

class UserModel {
  final String userId;
  String? gaurdId;
  final String userName;
  final String name;
  final String photoPath;
  final String roleId;
  final String siteId;
  final String companyId;
  final String? deviceToken;
  final String? deviceId;
  final String? email;
  final String? phone;
  final String? token;
  final String? clockIn;
  final String? clockOut;
  var clockStatus;
  final String? todayPatrolStatus;
  final String? attendanceStatus;
  final Map<String, dynamic>? issuesCount;
  String? logId;
  String? issue_radius;
  var isAdmin;
  
  // New fields from updated API response
  final String? password;
  final String? apkversion;
  final String? apkUrl;
  
  // Fields from companyLoc
  final bool? safetyCheckInEnabled;
  final int? safetyCheckInIntervalSeconds;
  final bool? liveTrackingEnabled;
  final int? liveTrackingIntervalSeconds;

  UserModel({
    required this.userId,
    required this.userName,
    required this.name,
    required this.photoPath,
    required this.roleId,
    required this.siteId,
    required this.companyId,
    this.gaurdId,
    this.deviceToken,
    this.deviceId,
    this.email,
    this.phone,
    this.token,
    this.clockIn,
    this.clockOut,
    this.clockStatus,
    this.todayPatrolStatus,
    this.attendanceStatus,
    this.issuesCount,
    this.logId,
    this.issue_radius,
    this.isAdmin = false, // Default value for isAdmin
    
    // New fields
    this.password,
    this.apkversion,
    this.apkUrl,
    
    // CompanyLoc fields
    this.safetyCheckInEnabled,
    this.safetyCheckInIntervalSeconds,
    this.liveTrackingEnabled,
    this.liveTrackingIntervalSeconds,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Extract companyLoc data
    final companyLoc = json['companyLoc'] as Map<String, dynamic>?;
    
    return UserModel(
      userId: json['userID']?.toString() ?? json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      photoPath: json['photoPath']?.toString() ?? '',
      roleId: json['roleID']?.toString() ?? json['roleId']?.toString() ?? '',
      siteId: json['siteId']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      deviceToken: json['deviceToken']?.toString() ?? json['token']?.toString(),
      deviceId: json['deviceID']?.toString() ?? json['deviceId']?.toString(),
      email: json['email']?.toString() ?? json['email_No']?.toString(),
      phone: json['phone']?.toString() ?? json['mobile_No']?.toString() ?? json['mobileNo']?.toString(),
      token: json['token']?.toString() ?? json['deviceToken']?.toString(),
      clockIn: json['clockIn']?.toString(),
      clockOut: json['clockOut']?.toString(),
      clockStatus: json['clockStatus'] is bool
          ? json['clockStatus']
          : json['clockStatus']?.toString().toLowerCase() == 'true',
      todayPatrolStatus: json['todayPatrolStatus']?.toString(),
      attendanceStatus: json['attendanceStatus']?.toString(),
      issuesCount: json['issuesCount'] != null ? Map<String, dynamic>.from(json['issuesCount']) : null,
      logId: json['logID']?.toString() ?? json['logId']?.toString() ?? '',
      isAdmin: json['isadmin'] == true || json['isadmin']?.toString().toLowerCase() == 'true',
      gaurdId: json['gaurdId']?.toString() ?? json['gaurdID']?.toString() ?? '', // Added gaurdId
      issue_radius: json['issue_radius']?.toString() ?? '500', // Added issue_radius
      
      // New fields from API response
      password: json['password']?.toString(),
      apkversion: json['apkversion']?.toString(),
      apkUrl: json['apkUrl']?.toString(),
      
      // Extract specific fields from companyLoc
      safetyCheckInEnabled: companyLoc?['safetyCheckInEnabled'] as bool?,
      safetyCheckInIntervalSeconds: companyLoc?['safetyCheckInIntervalSeconds'] as int?,
      liveTrackingEnabled: companyLoc?['liveTrackingEnabled'] as bool?,
      liveTrackingIntervalSeconds: companyLoc?['liveTrackingIntervalSeconds'] as int?,
    );
  }

  // Add this method to your UserModel class
  UserModel updateWith(Map<String, dynamic> json) {
    // Extract companyLoc data
    final companyLoc = json['companyLoc'] as Map<String, dynamic>?;
    
    return UserModel(
      userId: json['userID']?.toString() ?? json['userId']?.toString() ?? this.userId,
      gaurdId: json['gaurdId']?.toString() ?? json['gaurdID']?.toString() ?? this.gaurdId,
      userName: json['userName']?.toString() ?? this.userName,
      name: json['name']?.toString() ?? this.name,
      photoPath: json['photoPath']?.toString() ?? this.photoPath,
      roleId: json['roleID']?.toString() ?? json['roleId']?.toString() ?? this.roleId,
      siteId: json['siteId']?.toString() ?? this.siteId,
      companyId: json['companyId']?.toString() ?? this.companyId,
      deviceToken: json['deviceToken']?.toString() ?? json['token']?.toString() ?? this.deviceToken,
      deviceId: json['deviceID']?.toString() ?? json['deviceId']?.toString() ?? this.deviceId,
      email: json['email']?.toString() ?? json['email_No']?.toString() ?? this.email,
      phone: json['phone']?.toString() ?? json['mobile_No']?.toString() ?? json['mobileNo']?.toString() ?? this.phone,
      token: json['token']?.toString() ?? json['deviceToken']?.toString() ?? this.token,
      clockIn: json['clockIn']?.toString() ?? this.clockIn,
      clockOut: json['clockOut']?.toString() ?? this.clockOut,
      clockStatus: json['clockStatus'] != null 
          ? (json['clockStatus'] is bool 
              ? json['clockStatus'] 
              : json['clockStatus']?.toString().toLowerCase() == 'true')
          : this.clockStatus,
      todayPatrolStatus: json['todayPatrolStatus']?.toString() ?? this.todayPatrolStatus,
      attendanceStatus: json['attendanceStatus']?.toString() ?? this.attendanceStatus,
      issuesCount: json['issuesCount'] != null 
          ? Map<String, dynamic>.from(json['issuesCount']) 
          : this.issuesCount,
      logId: json['logID']?.toString() ?? json['logId']?.toString() ?? this.logId,
      issue_radius: json['issue_radius']?.toString() ?? this.issue_radius,
      isAdmin: json['isadmin'] == true || json['isadmin']?.toString().toLowerCase() == 'true' || this.isAdmin,
      
      // New fields
      password: json['password']?.toString() ?? this.password,
      apkversion: json['apkversion']?.toString() ?? this.apkversion,
      apkUrl: json['apkUrl']?.toString() ?? this.apkUrl,
      
      // CompanyLoc fields
      safetyCheckInEnabled: companyLoc?['safetyCheckInEnabled'] as bool? ?? this.safetyCheckInEnabled,
      safetyCheckInIntervalSeconds: companyLoc?['safetyCheckInIntervalSeconds'] as int? ?? this.safetyCheckInIntervalSeconds,
      liveTrackingEnabled: companyLoc?['liveTrackingEnabled'] as bool? ?? this.liveTrackingEnabled,
      liveTrackingIntervalSeconds: companyLoc?['liveTrackingIntervalSeconds'] as int? ?? this.liveTrackingIntervalSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userId,
      'userName': userName,
      'name': name,
      'photoPath': photoPath,
      'roleID': roleId,
      'siteId': siteId,
      'companyId': companyId,
      'deviceToken': deviceToken,
      'deviceID': deviceId,
      'email': email,
      'phone': phone,
      'token': token,
      'clockIn': clockIn,
      'clockOut': clockOut,
      'clockStatus': clockStatus,
      'todayPatrolStatus': todayPatrolStatus,
      'attendanceStatus': attendanceStatus,
      'issuesCount': issuesCount,
      'logID': logId,
      'isAdmin': isAdmin,
      'gaurdId': gaurdId,
      'issue_radius': issue_radius,
      
      // New fields
      'password': password,
      'apkversion': apkversion,
      'apkUrl': apkUrl,
      
      // CompanyLoc fields - storing as individual fields for easy access
      'safetyCheckInEnabled': safetyCheckInEnabled,
      'safetyCheckInIntervalSeconds': safetyCheckInIntervalSeconds,
      'liveTrackingEnabled': liveTrackingEnabled,
      'liveTrackingIntervalSeconds': liveTrackingIntervalSeconds,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  static UserModel? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return UserModel.fromJson(json);
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  UserModel copyWith({
    String? userId,
    String? userName,
    String? name,
    String? photoPath,
    String? roleId,
    String? siteId,
    String? companyId,
    String? deviceToken,
    String? deviceId,
    String? email,
    String? phone,
    String? token,
    String? clockIn,
    String? clockOut,
    dynamic clockStatus, // Changed to dynamic to handle bool/null
    String? todayPatrolStatus,
    String? attendanceStatus,
    Map<String, dynamic>? issuesCount,
    String? logId,
    bool? isAdmin,
    String? gaurdId,
    String? issue_radius,
    
    // New fields
    String? password,
    String? apkversion,
    String? apkUrl,
    
    // CompanyLoc fields
    bool? safetyCheckInEnabled,
    int? safetyCheckInIntervalSeconds,
    bool? liveTrackingEnabled,
    int? liveTrackingIntervalSeconds,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      gaurdId: gaurdId ?? this.gaurdId,
      userName: userName ?? this.userName,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      roleId: roleId ?? this.roleId,
      siteId: siteId ?? this.siteId,
      companyId: companyId ?? this.companyId,
      deviceToken: deviceToken ?? this.deviceToken,
      deviceId: deviceId ?? this.deviceId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      clockStatus: clockStatus ?? this.clockStatus,
      todayPatrolStatus: todayPatrolStatus ?? this.todayPatrolStatus,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      issuesCount: issuesCount ?? this.issuesCount,
      logId: logId ?? this.logId,
      isAdmin: isAdmin ?? this.isAdmin,
      issue_radius: issue_radius ?? this.issue_radius,
      
      // New fields
      password: password ?? this.password,
      apkversion: apkversion ?? this.apkversion,
      apkUrl: apkUrl ?? this.apkUrl,
      
      // CompanyLoc fields
      safetyCheckInEnabled: safetyCheckInEnabled ?? this.safetyCheckInEnabled,
      safetyCheckInIntervalSeconds: safetyCheckInIntervalSeconds ?? this.safetyCheckInIntervalSeconds,
      liveTrackingEnabled: liveTrackingEnabled ?? this.liveTrackingEnabled,
      liveTrackingIntervalSeconds: liveTrackingIntervalSeconds ?? this.liveTrackingIntervalSeconds,
    );
  }

  bool get isValid => userId.isNotEmpty && name.isNotEmpty;

  @override
  String toString() {
    return 'UserModel{'
        'userId: $userId, '
        'userName: $userName, '
        'name: $name, '
        'email: $email, '
        'phone: $phone, '
        'apkversion: $apkversion, '
        'safetyCheckInEnabled: $safetyCheckInEnabled, '
        'liveTrackingEnabled: $liveTrackingEnabled'
        '}';
  }
}