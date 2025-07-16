import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ConnectivityController>(() => ConnectivityController());
  }
}

class ConnectivityController extends GetxController {
  final isOffline = false.obs;
  final _connectionType = MConnectivityResult.none.obs;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription _streamSubscription;

  MConnectivityResult get connectionType => _connectionType.value;
  bool _isFirstCheck = true; // Flag to suppress snackbar during first check

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

  void showNoInternetSnackbar() {


Get.snackbar(
  "No Internet Connection",
  "Please check your network settings.",
  backgroundColor: Colors.orange.shade600,
  colorText: Colors.white,
  snackPosition: SnackPosition.BOTTOM,
  margin: const EdgeInsets.all(12),
  borderRadius: 10,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  icon: const Icon(Icons.warning, color: Colors.white),
  shouldIconPulse: false,
  duration: const Duration(seconds: 2),
  barBlur: 10,
  overlayBlur: 2,
);

  }

  void showInternetRestoredSnackbar() {
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
      duration: const Duration(seconds: 2),
      barBlur: 10,
      overlayBlur: 2,
    );
  }

  bool shouldBlockApiCall() {
    if (isOffline.value) {
      showNoInternetSnackbar();
      return true;
    }
    return false;
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
    if (_isFirstCheck) {
      _isFirstCheck = false;
      connectionType = MConnectivityResult.mobile;
      isOffline.value = result == ConnectivityResult.none;
      return;
    }

    print("This is connnectivity result: $result");
    switch (result) {
      case ConnectivityResult.wifi:
        connectionType = MConnectivityResult.wifi;
        showInternetRestoredSnackbar();
        isOffline.value = false;

        break;
      case ConnectivityResult.mobile:
        connectionType = MConnectivityResult.mobile;
        showInternetRestoredSnackbar();
        isOffline.value = false;

        break;
      case ConnectivityResult.none:
        connectionType = MConnectivityResult.none;
        showNoInternetSnackbar();
        isOffline.value = true;
        break;
      default:
        print('Failed to get connection type');
        break;
    }
  }

  @override
  void onClose() {
    _streamSubscription.cancel();
  }
}

enum MConnectivityResult { none, wifi, mobile }
