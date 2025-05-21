import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/attandance/GuardAttendanceScreen.dart';
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/modules/profile/Profile_screen.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/bottomnavigation.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String currentMonth = 'March 2024';


  final List<AttendanceRecord> attendanceRecords = [
    AttendanceRecord(
      date: DateTime(2024, 3, 18),
      checkIn: '09:00 AM',
      checkOut: '06:30 PM',
      avatarUrl: 'https://randomuser.me/api/portraits/women/34.jpg',
    ),
    AttendanceRecord(
      date: DateTime(2024, 3, 15),
      checkIn: '08:45 AM',
      checkOut: '05:15 PM',
      avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
    ),
    AttendanceRecord(
      date: DateTime(2024, 3, 14),
      checkIn: '09:15 AM',
      checkOut: '06:45 PM',
      avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
    ),
    AttendanceRecord(
      date: DateTime(2024, 3, 13),
      checkIn: '08:30 AM',
      checkOut: '05:30 PM',
      avatarUrl: 'https://randomuser.me/api/portraits/men/55.jpg',
    ),
    AttendanceRecord(
      date: DateTime(2024, 3, 12),
      checkIn: '09:30 AM',
      checkOut: '06:00 PM',
      avatarUrl: 'https://randomuser.me/api/portraits/men/63.jpg',
    ),
    AttendanceRecord(
      date: DateTime(2024, 3, 11),
      checkIn: '09:00 AM',
      checkOut: '06:30 PM',
      avatarUrl: 'https://randomuser.me/api/portraits/women/71.jpg',
    ),
  ];

  void _previousMonth() {
    setState(() {
      // For demo, simply changing the label
      currentMonth = 'February 2024';
    });
  }

  void _nextMonth() {
    setState(() {
      // For demo, simply changing the label
      currentMonth = 'April 2024';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: ListView.builder(
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                return _buildAttendanceCard(attendanceRecords[index]);
              },
            ),
          ),
        ],
      ),
      // bottomNavigationBar: bottomnavcontroller.buildScreen(),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.whiteColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(currentMonth, style: AppTextStyles.heading),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    // Calculate duration
    final duration = _calculateDuration(record.checkIn, record.checkOut);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(record.avatarUrl),
                  radius: 16,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(record.date),
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.checkIn} - ${record.checkOut}',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 4),
                    Text(duration, style: AppTextStyles.body),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'IN',
                        style: TextStyle(
                          color: AppColors.greenColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OUT',
                        style: TextStyle(
                          color: AppColors.greyColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('E, MMM d');
    return formatter.format(date);
  }

  String _calculateDuration(String checkIn, String checkOut) {
    // Parse the times for calculation
    final DateFormat format = DateFormat('hh:mm a');
    final DateTime inTime = format.parse(checkIn);
    final DateTime outTime = format.parse(checkOut);

    // Calculate the difference
    final Duration difference = outTime.difference(inTime);

    // Format as hours and minutes
    final int hours = difference.inHours;
    final int minutes = difference.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  // Widget _buildBottomNavBar() {
  //   return Obx(() => BottomNavigationBar(
  //     currentIndex: controller.selectedIndex.value,
  //     onTap: (index) {
  //       controller.selectedIndex.value = index;
  //       switch (index) {
  //         case 0:
  //           break;
  //         case 1:
  //           Get.to(() => PatrolCheckInScreen());
  //           break;
  //         case 2:
  //           Get.to(() => IncidentReportScreen());
  //           break;
  //         case 3:
  //           Get.to(() => GuardAttendanceScreen());
  //           break;
  //         case 4:
  //           Get.to(() => ProfileScreen());
  //           break;
  //       }
  //     },
  //     type: BottomNavigationBarType.fixed,
  //     selectedItemColor: Color(0xFF1E3A8A),
  //     unselectedItemColor: Colors.grey,
  //     items: [
  //       BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
  //       BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Patrol'),
  //       BottomNavigationBarItem(icon: Icon(Icons.error_outline), label: 'Issues'),
  //       BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Attendance'),
  //       BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  //     ],
  //   ));
}

class AttendanceRecord {
  final DateTime date;
  final String checkIn;
  final String checkOut;
  final String avatarUrl;

  AttendanceRecord({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.avatarUrl,
  });
}
