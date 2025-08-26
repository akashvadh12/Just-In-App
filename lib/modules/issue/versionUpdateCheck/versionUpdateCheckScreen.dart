import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';

class VersionChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    final newVersion = NewVersionPlus(
      iOSId: 'com.example.ios', // replace with your iOS bundle id
      androidId: 'com.example.android', // replace with your Android package name
    );

    final status = await newVersion.getVersionStatus();
    if (status != null && status.canUpdate) {
      _showUpdateDialog(context, newVersion, status);
    }
  }

  static void _showUpdateDialog(
      BuildContext context, NewVersionPlus newVersion, VersionStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Available"),
          content: Text(
              "A new version (${status.storeVersion}) is available.\n\n"
              "You're using ${status.localVersion}. Please update to continue."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog
                await newVersion.launchAppStore(status.appStoreLink); 
                // ✅ now passing the Play Store / App Store link
              },
              child: const Text("Update Now"),
            ),
          ],
        );
      },
    );
  }
}
