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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userID'] ?? '',
      userName: json['userName'] ?? '',
      name: json['name'] ?? '',
      photoPath: json['photoPath'] ?? '',
      roleId: json['roleID'] ?? '',
      siteId: json['siteId'] ?? '',
      companyId: json['companyId'] ?? '',
      deviceToken: json['deviceToken'],
      deviceId: json['deviceID'],
      email: json['email'],
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
    };
  }

  // Convert user model to JSON string for storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Create user model from JSON string from storage
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
}
