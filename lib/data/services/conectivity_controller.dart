import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController {
  final isOffline = false.obs;
  final _connectionType = MConnectivityResult.none.obs;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription _streamSubscription;
  bool _isDialogShowing = false;
  bool _isFirstCheck = true;

  MConnectivityResult get connectionType => _connectionType.value;

  set connectionType(value) {
    _connectionType.value = value;
  }

  @override
  void onReady() {
    super.onReady();
    getConnectivityType();
    _streamSubscription =
        _connectivity.onConnectivityChanged.listen((connectivityResult) {
      _updateState(connectivityResult.first);
    });
  }

  // Centralized method - shows dialog only once
  void _showNoInternetDialog() {
    if (_isDialogShowing) return; // Prevent multiple dialogs
    
    _isDialogShowing = true;
    
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder(
                  duration: const Duration(seconds: 2),
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 40,
                          color: Colors.red.shade600,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your network settings and try again',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for connection...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
    );
  }

  void _hideNoInternetDialog() {
    if (_isDialogShowing) {
      _isDialogShowing = false;
      Get.back();
      _showInternetRestoredSnackbar();
    }
  }

  void _showInternetRestoredSnackbar() {
    Get.snackbar(
      "Internet Restored",
      "You are now connected to the internet.",
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      icon: const Icon(Icons.check_circle, color: Colors.white),
      shouldIconPulse: false,
      duration: const Duration(seconds: 3),
      barBlur: 10,
    );
  }

  // Simple boolean check for API calls - NO UI logic here
  bool get hasConnection => !isOffline.value;

  // Optional: Method to manually check if API should proceed
  bool canMakeApiCall() {
    return hasConnection;
  }

  Future<void> getConnectivityType() async {
    late ConnectivityResult connectivityResult;
    try {
      connectivityResult =
          (await (_connectivity.checkConnectivity())) as ConnectivityResult;
    } on PlatformException catch (e) {
      print(e);
    }
    return _updateState(connectivityResult);
  }

  _updateState(ConnectivityResult result) {
    bool wasOffline = isOffline.value;

    if (_isFirstCheck) {
      _isFirstCheck = false;
      connectionType = MConnectivityResult.mobile;
      isOffline.value = result == ConnectivityResult.none;
      
      // Show dialog immediately if offline on first check
      if (isOffline.value) {
        _showNoInternetDialog();
      }
      return;
    }

    print("Connectivity result: $result");
    
    switch (result) {
      case ConnectivityResult.wifi:
        connectionType = MConnectivityResult.wifi;
        isOffline.value = false;
        
        // Only hide dialog if we were previously offline
        if (wasOffline) {
          _hideNoInternetDialog();
        }
        break;
        
      case ConnectivityResult.mobile:
        connectionType = MConnectivityResult.mobile;
        isOffline.value = false;
        
        // Only hide dialog if we were previously offline
        if (wasOffline) {
          _hideNoInternetDialog();
        }
        break;
        
      case ConnectivityResult.none:
        connectionType = MConnectivityResult.none;
        isOffline.value = true;
        
        // Only show dialog if we weren't already offline
        if (!wasOffline) {
          _showNoInternetDialog();
        }
        break;
        
      default:
        print('Failed to get connection type');
        break;
    }
  }

  @override
  void onClose() {
    _streamSubscription.cancel();
    super.onClose();
  }
}

enum MConnectivityResult { none, wifi, mobile }
