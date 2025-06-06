import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:security_guard/modules/auth/models/user_model.dart';

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

  // User data methods
  Future<void> saveUserData({
    String? name,
    String? email,
    String? phone,
    String? userId,
    String? profileImage,
  }) async {
    if (name != null) await _prefs.setString('user_name', name);
    if (email != null) await _prefs.setString('user_email', email);
    if (phone != null) await _prefs.setString('user_phone', phone);
    if (userId != null) await _prefs.setString('user_id', userId);
    if (profileImage != null)
      await _prefs.setString('profile_image', profileImage);
  }

  // Get user data
  String? getUserName() => _prefs.getString('user_name');
  String? getUserEmail() => _prefs.getString('user_email');
  String? getUserPhone() => _prefs.getString('user_phone');
  String? getUserId() => _prefs.getString('user_id');
  String? getProfileImage() => _prefs.getString('profile_image');

  // Authentication token methods - Fixed to use consistent keys
  Future<void> saveToken(String token) async {
    try {
      await _prefs.setString('auth_token', token);
      print('Token saved successfully: ${token.isNotEmpty ? 'Token exists' : 'Empty token'}');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  String? getToken() {
    try {
      final token = _prefs.getString('auth_token');
      print('Retrieved token: ${token?.isNotEmpty == true ? 'Token exists' : 'No token found'}');
      return token;
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  // Device token methods - Separate from auth token for clarity
  Future<void> saveDeviceToken(String deviceToken) async {
    try {
      await _prefs.setString('device_token', deviceToken);
      print('Device token saved successfully');
    } catch (e) {
      print('Error saving device token: $e');
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

  // Login status methods
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    try {
      await _prefs.setBool('is_logged_in', isLoggedIn);
      print('Login status saved: $isLoggedIn');
    } catch (e) {
      print('Error saving login status: $e');
    }
  }

  bool isLoggedIn() {
    try {
      return _prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Save complete user model
  Future<void> saveUserModel(UserModel user) async {
    try {
      await _prefs.setString('user_data', user.toJsonString());

      // Also save individual fields for backward compatibility
      await saveUserData(
        name: user.name,
        email: user.email,
        userId: user.userId,
        profileImage: user.photoPath,
      );

      print('User model saved successfully');
    } catch (e) {
      print('Error saving user model: $e');
    }
  }

  // Get complete user model
  UserModel? getUserModel() {
    try {
      final userDataString = _prefs.getString('user_data');
      return UserModel.fromJsonString(userDataString);
    } catch (e) {
      print('Error retrieving user model: $e');
      return null;
    }
  }

  // Check if user has valid session (logged in AND has token)
  bool hasValidSession() {
    return isLoggedIn() && getToken()?.isNotEmpty == true;
  }

  // Clear all user data (for logout)
  Future<void> clearUserData() async {
    try {
      await _prefs.remove('user_name');
      await _prefs.remove('user_email');
      await _prefs.remove('user_phone');
      await _prefs.remove('user_id');
      await _prefs.remove('profile_image');
      await _prefs.remove('auth_token');
      await _prefs.remove('device_token');
      await _prefs.remove('is_logged_in');
      await _prefs.remove('user_data');

      print('User data cleared successfully');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Generic methods for any key-value storage
  Future<void> saveString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e) {
      print('Error saving string with key $key: $e');
    }
  }

  Future<void> saveBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e) {
      print('Error saving bool with key $key: $e');
    }
  }

  Future<void> saveInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e) {
      print('Error saving int with key $key: $e');
    }
  }

  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      print('Error getting string with key $key: $e');
      return null;
    }
  }

  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      print('Error getting bool with key $key: $e');
      return null;
    }
  }

  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      print('Error getting int with key $key: $e');
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e) {
      print('Error removing key $key: $e');
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