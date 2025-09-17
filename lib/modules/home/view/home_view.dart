// File: lib/modules/home/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/data/services/sos_checkin_service.dart';
import 'package:security_guard/modules/Compony/compony_location_list.dart';
import 'package:security_guard/modules/addLoacation/location_list_screen.dart';
import 'package:security_guard/modules/home/controllers/home_controller.dart';
import 'package:security_guard/modules/issue/issue_list/controller/issue_controller.dart';
import 'package:security_guard/modules/issue/issue_list/issue_view/issue_screen.dart';
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';
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
      // Add floating SOS button for guards
      // floatingActionButton: _buildSosFloatingButton(),
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
      toolbarHeight: 70,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.profileController.userModel.value?.name.toString().split(" ").first ?? 
                    "$greeting",
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

          // SOS Status Indicator
          _buildSosStatusIndicator(),

          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Get.to(() => NotificationsScreen());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSosStatusIndicator() {
    return Obx(() {
      final isAdmin = controller.profileController.userModel.value?.isAdmin == true;
      if (isAdmin) return SizedBox.shrink(); // Don't show for admins
      
      final sosService = Get.find<SosCheckInService>();
      final isActive =  controller.profileController.userModel.value?.safetyCheckInEnabled == true;
      final isPending = sosService.isCheckInPending.value;
      
      return Container(
        margin: EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => _showSosStatusDialog(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPending 
                  ? Colors.orange 
                  : isActive 
                      ? Colors.green 
                      : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(
              isPending ? Icons.timer : Icons.security,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    });
  }

  // Widget _buildSosFloatingButton() {
  //   return Obx(() {
  //     final isAdmin = controller.profileController.userModel.value?.isAdmin == true;
  //     if (isAdmin) return SizedBox.shrink(); // Don't show for admins
      
  //     return FloatingActionButton(
  //       onPressed: () => _showSosDialog(),
  //       backgroundColor: Colors.red,
  //       child: Icon(Icons.emergency, color: Colors.white),
  //       heroTag: "sosButton",
  //       tooltip: 'Emergency SOS',
  //     );
  //   });
  // }

  Widget _buildBody(bottomNavController) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceCard(),
          SizedBox(height: 16),
          _buildSosStatusCard(), // New SOS status card
          SizedBox(height: 24),
          _buildSectionTitle('Quick Actions'),
          SizedBox(height: 12),
          _buildQuickActions(bottomNavController),
          SizedBox(height: 24),
          _buildSectionTitle('Today\'s Overview'),
          SizedBox(height: 12),
          _buildOverviewCards(bottomNavController),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSosStatusCard() {
    return Obx(() {
      final isAdmin = controller.profileController.userModel.value?.isAdmin == true;
      if (isAdmin) return SizedBox.shrink(); // Don't show for admins
      
      final sosService = Get.find<SosCheckInService>();
      final isActive = sosService.isServiceActive.value;
      final isPending = sosService.isCheckInPending.value;
      final lastCheckIn = sosService.lastCheckInTime.value;
      final missedCheckIns = sosService.missedCheckIns.value;
      
      return Container(
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
                  'Safety Check-In Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending 
                        ? Color(0xFFFFF3CD)
                        : isActive 
                            ? Color(0xFFE6F7EE) 
                            : Color(0xFFFFE6E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPending 
                        ? 'Pending Response'
                        : isActive 
                            ? 'Active' 
                            : 'Inactive',
                    style: TextStyle(
                      color: isPending 
                          ? Colors.orange[800]
                          : isActive 
                              ? Color(0xFF4CAF50) 
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
                      'Last Check-in',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      lastCheckIn.isEmpty ? 'None' : lastCheckIn,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missed',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      missedCheckIns.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: missedCheckIns > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                // GestureDetector(
                //   onTap: () => controller.toggleSosService(),
                //   child: Container(
                //     padding: EdgeInsets.all(8),
                //     decoration: BoxDecoration(
                //       color: isActive ? Colors.red[100] : Colors.green[100],
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Icon(
                //       isActive ? Icons.stop : Icons.play_arrow,
                //       color: isActive ? Colors.red : Colors.green,
                //       size: 20,
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      );
    });
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
                        ? controller.attendanceStatus.value == "In" ?
                            'Clock-in' : 'Clock-out'

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
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  controller.attendanceStatus.value != 'Out'
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clock-in',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            controller.clockInTime.value,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clock-out',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            controller.clockOutTime.value,
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
    return Obx(
      () => controller.profileController.userModel.value?.isAdmin == true
          ? _buildAdminQuickActions(bottomNavController)
          : _buildNonAdminQuickActions(bottomNavController),
    );
  }

  Widget _buildAdminQuickActions(bottomNavController) {
    return Container(
      child: 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: _buildActionButton(
                    icon: Icons.add_location,
                    label: 'Add\nLocation',
                    color: Color.fromARGB(255, 30, 107, 231),
                    onTap: () => Get.to(LocationsListScreen()),
                  ),
                ),
              ),
          
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  
                  child: _buildActionButton(
                    icon: Icons.business,
                    label: 'Company\nLocation',
                    color: Color.fromARGB(255, 30, 107, 231),
                    onTap: () {
                      Get.to(CompanyLocationsListScreen());
                    },
                  ),
                ),
              ),
                  Expanded(
                child: Padding(
                 padding: EdgeInsets.only(left: 4),
                  child: _buildActionButton(
                    icon: Icons.warning,
                    label: 'Issues',
                    color: Color.fromARGB(255, 30, 107, 231),
                    onTap: () => bottomNavController.changeTab(3)
                  ),
                ),
              ),
            ],
          ),
     
    );
  }

  Widget _buildNonAdminQuickActions(bottomNavController) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 4),
              child: _buildActionButton(
                icon: Icons.fingerprint,
                label: 'Mark\nAttendance',
                color: Color.fromARGB(255, 30, 107, 231),
                onTap: () => bottomNavController.changeTab(1),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: _buildActionButton(
                icon: Icons.directions_walk,
                label: 'Start\nPatrol',
                color: Color.fromARGB(255, 30, 107, 231),
                onTap: () => bottomNavController.changeTab(2),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: _buildActionButton(
                icon: Icons.warning,
                label: 'Raise\nIssue',
                color: Color.fromARGB(255, 30, 107, 231),
                onTap: () {
                  Get.to(
                    () => IncidentReportScreen(),
                    binding: BindingsBuilder(() {
                      Get.put(IssuesController());
                    }),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
      () => Column(
        children: [
          InkWell(
            onTap: () => bottomNavController.changeTab(3),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
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
                        'New Issues',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fiber_new,
                          color: Colors.green[600],
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${controller.issuesNew}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12),

          InkWell(
            onTap: () => {Get.to(() => IssuesScreen(initialTabIndex: 1))},
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
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
                        'Resolved Issues',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.blue[600],
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${controller.issuesResolved}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _showSosDialog() {
  //   Get.dialog(
  //     AlertDialog(
  //       title: Row(
  //         children: [
  //           Icon(Icons.emergency, color: Colors.red),
  //           SizedBox(width: 8),
  //           Text('Emergency SOS'),
  //         ],
  //       ),
  //       content: Text(
  //         'Are you sure you want to send an emergency SOS alert? This will notify admin and authorities immediately.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Get.back();
  //             // controller.triggerManualSos();
  //           },
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: Text('Send SOS', style: TextStyle(color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showSosStatusDialog() {
    final sosService = Get.find<SosCheckInService>();
    
    Get.dialog(
      AlertDialog(
        title: Text('Safety Check-In Status'),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Service Status', sosService.isServiceActive.value ? 'Active' : 'Inactive'),
            _buildStatusRow('Check-in Interval', '${sosService.checkInIntervalMinutes.value} minutes'),
            _buildStatusRow('Response Window', '${sosService.responseWindowMinutes.value} minutes'),
            _buildStatusRow('Last Check-in', sosService.lastCheckInTime.value.isEmpty ? 'None' : sosService.lastCheckInTime.value),
            _buildStatusRow('Missed Check-ins', sosService.missedCheckIns.value.toString()),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // controller.toggleSosService();
            },
            child: Text(sosService.isServiceActive.value ? 'Stop Service' : 'Start Service'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Color _getActivityColor(String type) {
  //   switch (type) {
  //     case 'patrol':
  //       return Colors.blue;
  //     case 'attendance':
  //       return Colors.purple;
  //     case 'issue':
  //       return Colors.orange;
  //     default:
  //       return Colors.grey;
  //   }
  // }
}