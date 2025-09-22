// Create this new file: lib/services/app_lifecycle_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;

import 'package:security_guard/data/services/sos_checkin_service.dart';

class AppLifecycleService extends GetxController with WidgetsBindingObserver {
  static AppLifecycleService get instance => Get.find<AppLifecycleService>();
  
  final SosCheckInService _sosService = Get.find<SosCheckInService>();
  static const String _logTag = '[AppLifecycleService]';
  
  AppLifecycleState? _lastState;
  DateTime? _backgroundTime;
  
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    dev.log('$_logTag Lifecycle observer added');
  }
  
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    dev.log('$_logTag App lifecycle changed: $_lastState -> $state');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // App is going to background
        _backgroundTime = DateTime.now();
        dev.log('$_logTag App going to background at $_backgroundTime');
        break;
        
      case AppLifecycleState.resumed:
        // App is coming back to foreground
        if (_lastState == AppLifecycleState.paused || 
            _lastState == AppLifecycleState.hidden ||
            _lastState == AppLifecycleState.inactive) {
          
          final backgroundDuration = _backgroundTime != null 
              ? DateTime.now().difference(_backgroundTime!).inSeconds 
              : 0;
              
          dev.log('$_logTag App resumed after ${backgroundDuration}s in background');
          
          // Check for pending safety check-ins after a short delay
          Future.delayed(const Duration(milliseconds: 1000), () {
            _sosService.checkPendingSafetyCheckIn();
          });
        }
        break;
        
      case AppLifecycleState.detached:
        // App is being terminated
        dev.log('$_logTag App being terminated');
        break;
    }
    
    _lastState = state;
  }
}