  // Mock LocalStorageService for demo purposes
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';

class LocalStorageService extends GetxService {
  void clearUserData() {
    // In real app, this would clear SharedPreferences or other storage
    print('User data cleared');
  }
  
  // Add other methods as needed for storage
}

// Add this to your app's main.dart or initialization
void initServices() {
  Get.put(LocalStorageService());
}