
import 'package:security_guard/core/api/api_client.dart';

class ApiGetServices {
  final ApiClient _client = ApiClient();


  void _logResponse(String endpoint, dynamic response, {dynamic error}) {
    if (error != null) {
      print('📡 API Error [$endpoint]: $error');
      return;
    }

    print('📡 API Response [$endpoint]: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');
  }

  Future<UserModel?> getCurrentUser(String firebaseToken) async {


    final response = await _client
        .get(MY_PROFILE, headers: {"Authorization": "Bearer $firebaseToken"});

    if (response.statusCode == 503) return null; // Avoid extra error message

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if the user account is marked for deletion
      if (data['success'] == true && data['user'] != null) {
        final userData = data['user'];

        // Check for deletion markers
        if ((userData['delete_request'] != null && userData['delete_request'] == 1) ||
            (userData['deleted_at'] != null && userData['deleted_at'].toString().isNotEmpty)) {

          // Sign out the user from Firebase
          final authController = Get.find<AuthController>();
          authController.signOut();

          // Show error message
          CustomSnackbar.showError(
            'Account Deletion in Progress',
            'This account has been marked for deletion and cannot be used. Please contact support if you need assistance.'
          );

          return null;
        }

        return UserModel.fromJson(userData);
      }
      return null;
    }
    _logResponse(MY_PROFILE, response);
    return null;
  }
}