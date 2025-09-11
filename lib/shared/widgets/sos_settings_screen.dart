// File: lib/modules/sos/sos_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/data/services/sos_checkin_service.dart';

class SosSettingsScreen extends StatelessWidget {
  const SosSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SosCheckInService sosService = Get.find<SosCheckInService>();
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('SOS Settings'),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceStatusCard(sosService),
            SizedBox(height: 24),
            _buildConfigurationCard(sosService),
            SizedBox(height: 24),
            _buildStatisticsCard(sosService),
            SizedBox(height: 24),
            _buildActionButtons(sosService),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCard(SosCheckInService sosService) {
    return Obx(() => Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: sosService.isServiceActive.value,
                onChanged: (value) {
                  if (value) {
                    sosService.startService();
                  } else {
                    sosService.stopService();
                  }
                },
                activeColor: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sosService.isServiceActive.value
                  ? Colors.green[50]
                  : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  sosService.isServiceActive.value
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: sosService.isServiceActive.value
                      ? Colors.green
                      : Colors.red,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sosService.isServiceActive.value
                        ? 'SOS check-in service is running. You will receive periodic safety prompts.'
                        : 'SOS check-in service is stopped. No safety prompts will be shown.',
                    style: TextStyle(
                      color: sosService.isServiceActive.value
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (sosService.isCheckInPending.value)
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Check-in pending! Please respond to the safety prompt.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildConfigurationCard(SosCheckInService sosService) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildConfigSlider(
            'Check-in Interval',
            '${sosService.checkInIntervalMinutes.value} minutes',
            sosService.checkInIntervalMinutes.value.toDouble(),
            5,
            120,
            (value) {
              sosService.updateConfiguration(intervalMinutes: value.round());
            },
            Icons.schedule,
          ),
          SizedBox(height: 24),
          _buildConfigSlider(
            'Response Window',
            '${sosService.responseWindowMinutes.value} minutes',
            sosService.responseWindowMinutes.value.toDouble(),
            1,
            10,
            (value) {
              sosService.updateConfiguration(responseMinutes: value.round());
            },
            Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSlider(
    String title,
    String value,
    double currentValue,
    double min,
    double max,
    Function(double) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(Get.context!).copyWith(
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.blue[100],
            thumbColor: Colors.blue,
            overlayColor: Colors.blue.withAlpha(32),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: currentValue,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(SosCheckInService sosService) {
    return Obx(() => Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Last Check-in',
                  sosService.lastCheckInTime.value.isEmpty
                      ? 'None'
                      : sosService.lastCheckInTime.value,
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Missed Count',
                  sosService.missedCheckIns.value.toString(),
                  Icons.warning,
                  sosService.missedCheckIns.value > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Service Status',
                  sosService.isServiceActive.value ? 'Active' : 'Inactive',
                  Icons.security,
                  sosService.isServiceActive.value ? Colors.green : Colors.grey,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Next Check-in',
                  sosService.isServiceActive.value ? 'Scheduled' : 'N/A',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SosCheckInService sosService) {
    return Column(
      children: [
        // Test Check-in Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showTestCheckInDialog(sosService),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow),
                SizedBox(width: 8),
                Text(
                  'Test Check-in Dialog',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 12),
        
        // Emergency SOS Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showEmergencyDialog(sosService),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emergency),
                SizedBox(width: 8),
                Text(
                  'Emergency SOS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 12),
        
        // Reset Statistics Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showResetDialog(sosService),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text(
                  'Reset Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTestCheckInDialog(SosCheckInService sosService) {
    Get.dialog(
      AlertDialog(
        title: Text('Test Check-in'),
        content: Text('This will show the check-in dialog for testing purposes.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.dialog(const SosCheckInDialog());
            },
            child: Text('Show Dialog'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog(SosCheckInService sosService) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: Text(
          'Are you sure you want to send an emergency SOS alert? This will notify admin and authorities immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              sosService.handleCheckInResponse(CheckInStatus.sos);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Send SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(SosCheckInService sosService) {
    Get.dialog(
      AlertDialog(
        title: Text('Reset Statistics'),
        content: Text('This will reset missed check-ins count and last check-in time.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              sosService.missedCheckIns.value = 0;
              sosService.lastCheckInTime.value = '';
              Get.snackbar(
                'Statistics Reset',
                'All statistics have been reset successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }
}