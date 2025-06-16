import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService extends GetxService {
  static LocalStorageService get instance => Get.find<LocalStorageService>();

  late SharedPreferences _prefs;

  // Initialize the service
  Future<LocalStorageService> init() async {
    print('Initializing LocalStorageService...');
    try {
      _prefs = await SharedPreferences.getInstance();
      print('LocalStorageService initialized successfully');
      return this;
    } catch (e) {
      print('Error initializing LocalStorageService: $e');
      rethrow;
    }
  }

  Future<void> saveDeviceToken(String deviceToken) async {
    try {
      await _prefs.setString('device_token', deviceToken);
      print('Device token saved successfully');
    } catch (e) {
      print('Error saving device token: $e');
    }
  }
  Future<void> saveUserId(String userId) async {
    try {
      await _prefs.setString('user_id', userId);
      print('user Id  saved successfully for user: $userId');
    } catch (e) {
      print('Error saving User Id: $e');
    }
  }

  Future<String?> getUserId() async {
    try {
      return _prefs.getString('user_id');
    } catch (e) {
      print('Error retrieving user Id: $e');
      return null;
    }
  }

  String? getDeviceToken() {
    try {
      return _prefs.getString('device_token');
    } catch (e) {
      print('Error retrieving device token: $e');
      return null;
    }
  }

  Future<void> removeDeviceToken() async {
    try {
      await _prefs.remove('device_token');
    } catch (e) {
      print('Error removing device token: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _prefs.clear();
      print('All preferences cleared successfully');
    } catch (e) {
      print('Error clearing all preferences: $e');
    }
  }
}