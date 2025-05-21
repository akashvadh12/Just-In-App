import 'package:flutter/material.dart';
import 'package:security_guard/core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all as read',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Alerts'),
                const SizedBox(width: 8),
                _buildFilterChip('Reminders'),
              ],
            ),
          ),

          // Today Section
          _buildSectionHeader('Today'),

          // Today Notifications
          _buildNotificationItem(
            icon: Icons.error,
            iconColor: Colors.red,
            iconBackground: Colors.red[50]!,
            title: 'New issue assigned: Water leakage at Exit B',
            time: '2 min ago',
            dotColor: Colors.blue,
          ),
          _buildNotificationItem(
            icon: Icons.watch_later,
            iconColor: Colors.orange,
            iconBackground: Colors.orange[50]!,
            title: 'Reminder: Patrol starts in 10 minutes',
            time: '32 min ago',
            dotColor: Colors.blue,
          ),
          _buildNotificationItem(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            iconBackground: Colors.green[50]!,
            title: 'You marked attendance at 9:02 AM',
            time: '2h ago',
            showDot: false,
          ),

          // Yesterday Section
          _buildSectionHeader('Yesterday'),

          // Yesterday Notifications
          _buildNotificationItem(
            icon: Icons.camera_alt,
            iconColor: Colors.red,
            iconBackground: Colors.red[50]!,
            title: 'Selfie not captured in last patrol check-in',
            time: 'Yesterday at 4:15 PM',
            showDot: false,
          ),
          _buildNotificationItem(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            iconBackground: Colors.green[50]!,
            title: 'Issue resolved: Trash near Gate A',
            time: 'Yesterday at 2:30 PM',
            showDot: false,
          ),

          // Earlier Section
          _buildSectionHeader('Earlier'),

          // Earlier Notifications
          _buildNotificationItem(
            icon: Icons.calendar_today,
            iconColor: Colors.blue,
            iconBackground: Colors.blue[50]!,
            title: 'Your schedule was updated for today',
            time: '2 days ago',
            showDot: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String time,
    Color dotColor = Colors.transparent,
    bool showDot = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showDot) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const SecurityApp());
}

class SecurityApp extends StatelessWidget {
  const SecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security App',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.whiteColor,
        ),
      ),
      home: const NotificationsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
