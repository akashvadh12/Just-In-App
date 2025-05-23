
import 'package:security_guard/core/api/api_client.dart';

class ApiPostServices {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> signupOrLogin({
    String? fcmId,
    required String firebaseToken,
    String? phone,
    String? email,
    required String loginType,
  }) async {
    final body = {
      if (phone !=
       null) "phone": phone,
      if (email != null) "email": email,
      "fcm_id": fcmId,
      "login_type": loginType,
    };
    final response = await ApiClient().post(SIGNUP_OR_LOGIN, body,
        headers: {"Authorization": "Bearer $firebaseToken"});

    // Always decode the response body, regardless of status code
    final responseData = jsonDecode(response.body);

    if (response.statusCode != 200) {
      log("API call failed: ==============> ${response.body}");

      // Check if the error is related to account deletion
      if (responseData["message"] != null) {
        String message = responseData["message"].toString().toLowerCase();
        if (message.contains("delete") ||
            message.contains("account has been marked for deletion") ||
            message.contains("account deletion") ||
            message.contains("deleted account")) {
          // Set success to false to ensure proper handling in the auth controller
          responseData["success"] = false;
        }
      }
    }

    return responseData;
  }
}