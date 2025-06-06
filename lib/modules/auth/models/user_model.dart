// ==================== UPDATED USER MODEL ====================
import 'dart:convert';

class UserModel {
  final String userId;
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

  UserModel({
    required this.userId,
    required this.userName,
    required this.name,
    required this.photoPath,
    required this.roleId,
    required this.siteId,
    required this.companyId,
    this.deviceToken,
    this.deviceId,
    this.email,
    this.phone,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
  }) {
    return UserModel(
      userId: userId ?? this.userId,
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
        'phone: $phone'
        '}';
  }
}
