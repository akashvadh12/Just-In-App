// File: lib/modules/home/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/modules/attandance/AttendanceScreen/GuardAttendanceScreen.dart';

import 'package:security_guard/modules/home/controllers/home_controller.dart';
import 'package:security_guard/modules/notification/notification_screen.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/navigation_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BottomNavController bottomNavController =
        Get.find<BottomNavController>();

    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut(() => HomeController());
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: _buildAppBar(bottomNavController),
      body: _buildBody(bottomNavController),
    );
  }

  AppBar _buildAppBar(bottomNavController) {
    String _weekday(int weekday) {
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[weekday - 1];
    }

    String _month(int month) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return months[month - 1];
    }

    String _getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
    }

    final today = DateTime.now();
    final greeting = _getGreeting();
    final dateString =
        "${_weekday(today.weekday)}, ${today.day} ${_month(today.month)}, ${today.year}";

    return AppBar(
      elevation: 0,
      backgroundColor: Color(0xFF1E3A8A),
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Obx(
            () => GestureDetector(
              onTap: () {
              bottomNavController.changeTab(4); // Navigate to Profile tab
              },
              child: Container(
                width: 42,
                height: 42,
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(
                      controller
                                  .profileController
                                  .userModel
                                  .value
                                  ?.photoPath
                                  .isNotEmpty ==
                              true
                          ? controller
                              .profileController
                              .userModel
                              .value!
                              .photoPath
                          : 'https://cdn-icons-png.flaticon.com/512/1053/1053244.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            // this is important
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$greeting, ${controller.profileController.userModel.value?.name.toString().split(" ").first ?? ''}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
      
                Text(
                  dateString,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bottomNavController) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceCard(),
          SizedBox(height: 24),
          _buildSectionTitle('Quick Actions'),
          SizedBox(height: 12),
          _buildQuickActions(bottomNavController),
          SizedBox(height: 24),
          _buildSectionTitle('Today\'s Overview'),
          SizedBox(height: 12),
          _buildOverviewCards(bottomNavController),
          SizedBox(height: 24),
          _buildSectionTitle('Recent Activities'),
          SizedBox(height: 12),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                  'Attendance Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        controller.attendanceStatus.value == 'In'
                            ? Color(0xFFE6F7EE)
                            : Color(0xFFFFE6E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.attendanceStatus.value.isNotEmpty
                        ? controller.attendanceStatus.value
                        : 'Not Marked',
                    style: TextStyle(
                      color:
                          controller.attendanceStatus.value == 'In'
                              ? Color(0xFF4CAF50)
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clock In',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      controller
                          .clockInTime
                          .value, // You can bind actual clock in time if available from API
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today Patrol',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      controller.todayPatrolStatus.value.isNotEmpty
                          ? controller.todayPatrolStatus.value
                          : '-',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black.withOpacity(0.8),
      ),
    );
  }

  Widget _buildQuickActions(bottomNavController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          icon: Icons.directions_walk,
          label: 'Start\nPatrol',
          color: Color(0xFF4285F4),
          onTap: () => bottomNavController.changeTab(2),
        ),
        _buildActionButton(
          icon: Icons.fingerprint,
          label: 'Mark\nAttendance',
          color: Color(0xFF4285F4),
          onTap: () => bottomNavController.changeTab(1),
        ),
        _buildActionButton(
          icon: Icons.warning,
          label: 'Raise\nIssue',
          color: Color(0xFF4285F4),
          onTap: () => bottomNavController.changeTab(3),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(bottomNavController) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => bottomNavController.changeTab(3),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      'New Issues',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${controller.issuesNew}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fiber_new,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => bottomNavController.changeTab(3),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      'Resolved Issues',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${controller.issuesResolved}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(
            () => ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.recentActivities.length,
              separatorBuilder: (context, index) => Divider(height: 16),
              itemBuilder: (context, index) {
                final activity = controller.recentActivities[index];
                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getActivityColor(
                          activity['type'] as String,
                        ).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: _getActivityColor(activity['type'] as String),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 4),
                          Text(
                            activity['time'] as String,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'patrol':
        return Colors.blue;
      case 'attendance':
        return Colors.purple;
      case 'issue':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
