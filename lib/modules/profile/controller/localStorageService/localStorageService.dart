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
    if (profileImage != null) await _prefs.setString('profile_image', profileImage);
  }

  // Get user data
  String? getUserName() => _prefs.getString('user_name');
  String? getUserEmail() => _prefs.getString('user_email');
  String? getUserPhone() => _prefs.getString('user_phone');
  String? getUserId() => _prefs.getString('user_id');
  String? getProfileImage() => _prefs.getString('profile_image');

  // Authentication methods
  Future<void> saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  String? getToken() => _prefs.getString('auth_token');

  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await _prefs.setBool('is_logged_in', isLoggedIn);
  }

  bool isLoggedIn() => _prefs.getBool('is_logged_in') ?? false;

  // Clear all user data (for logout)
  Future<void> clearUserData() async {
    try {
      await _prefs.remove('user_name');
      await _prefs.remove('user_email');
      await _prefs.remove('user_phone');
      await _prefs.remove('user_id');
      await _prefs.remove('profile_image');
      await _prefs.remove('auth_token');
      await _prefs.remove('is_logged_in');
      
      // Remove any other user-specific data
      print('User data cleared successfully');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Generic methods for any key-value storage
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}