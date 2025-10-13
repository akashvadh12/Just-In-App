import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';

class VersionChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    final newVersion = NewVersionPlus(
      iOSId: 'com.cairovision.justin', // replace with your iOS bundle id
      androidId: 'com.cairovision.justin', // replace with your Android package name
      
    );

    final status = await newVersion.getVersionStatus();
        print("Local:=============> ${status?.localVersion}, Store:==============> ${status?.storeVersion} ,canUpdate: ${status?.canUpdate}");
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Update Icon with Animation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update,
                color: Colors.white,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            const Text(
              "🚀 Exciting Update Available!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Version Info with better styling
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, 
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Current Version:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        status.localVersion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "New Version:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.storeVersion,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Benefits text
            const Text(
              "✨ Get the latest features, improvements, and bug fixes!\n"
              "🔒 Enhanced security and performance\n"
              "🎯 Better user experience awaits",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Update Button with gradient and animation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await newVersion.launchAppStore(status.appStoreLink);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF667eea),
                  elevation: 8,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.download,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Update Now",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle encouragement
            const Text(
              "Don't miss out on the latest improvements!",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  },
);
  }
}
