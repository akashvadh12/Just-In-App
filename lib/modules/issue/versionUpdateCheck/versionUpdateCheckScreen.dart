import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';

class VersionUpdateScreen extends StatefulWidget {
  const VersionUpdateScreen({Key? key}) : super(key: key);

  @override
  State<VersionUpdateScreen> createState() => _VersionUpdateScreenState();
}

class _VersionUpdateScreenState extends State<VersionUpdateScreen> {
  PackageInfo? packageInfo;
  String? latestVersion;
  bool isLoading = false;
  bool isUpdateAvailable = false;
  String? updateUrl;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Replace with your actual API endpoint or store URL
      // For Play Store: https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME
      // For App Store: https://itunes.apple.com/lookup?bundleId=YOUR_BUNDLE_ID
      
      String apiUrl;
      if (Platform.isAndroid) {
        // Example for Play Store API (you'll need to implement your own endpoint)
        apiUrl = 'https://your-api.com/check-version/android';
      } else {
        // Example for App Store API
        apiUrl = 'https://itunes.apple.com/lookup?bundleId=${packageInfo?.packageName}';
      }

      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (Platform.isAndroid) {
          // Handle your custom API response
          latestVersion = data['latest_version'];
          updateUrl = data['update_url'];
        } else {
          // Handle App Store response
          if (data['resultCount'] > 0) {
            latestVersion = data['results'][0]['version'];
            updateUrl = data['results'][0]['trackViewUrl'];
          }
        }

        // Compare versions
        if (latestVersion != null && packageInfo != null) {
          isUpdateAvailable = _isUpdateAvailable(packageInfo!.version, latestVersion!);
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = latestVersion.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      int currentPart = i < current.length ? current[i] : 0;
      int latestPart = i < latest.length ? latest[i] : 0;
      
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }

  Future<void> _launchUpdate() async {
    if (updateUrl != null) {
      final Uri url = Uri.parse(updateUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else {
      // Fallback URLs
      String fallbackUrl;
      if (Platform.isAndroid) {
        fallbackUrl = 'https://play.google.com/store/apps/details?id=${packageInfo?.packageName}';
      } else {
        fallbackUrl = 'https://apps.apple.com/app/id/YOUR_APP_ID'; // Replace with your App Store ID
      }
      
      final Uri url = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Version'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Version Card
            Card(
              elevation: 2,
              color: AppColors.whiteColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Version',
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('App Name', packageInfo?.appName ?? 'Loading...'),
                    _buildInfoRow('Version', packageInfo?.version ?? 'Loading...'),
                    _buildInfoRow('Build Number', packageInfo?.buildNumber ?? 'Loading...'),
                    _buildInfoRow('Package Name', packageInfo?.packageName ?? 'Loading...'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Update Status Card
            Card(
              elevation: 2,
              color: AppColors.whiteColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isUpdateAvailable ? Icons.system_update : Icons.check_circle_outline,
                          color: isUpdateAvailable ? Colors.orange : AppColors.greenColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Update Status',
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (isLoading)
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Checking for updates...'),
                        ],
                      )
                    else if (isUpdateAvailable)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              'Update Available',
                              style: AppTextStyles.hint.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (latestVersion != null)
                            Text(
                              'Latest Version: $latestVersion',
                              style: AppTextStyles.body,
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'A new version of the app is available. Update now to get the latest features and improvements.',
                            style: AppTextStyles.body,
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greenColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.greenColor),
                            ),
                            child: Text(
                              'Up to Date',
                              style: AppTextStyles.hint.copyWith(
                                color: AppColors.greenColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You are using the latest version of the app.',
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _checkForUpdates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLoading ? Icons.refresh : Icons.refresh,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLoading ? 'Checking...' : 'Check for Updates',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (isUpdateAvailable) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _launchUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: AppColors.whiteColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.system_update,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Update Now',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.hint.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}