import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/modules/attandance/AttendanceScreen/GuardAttendanceScreen.dart';

import 'package:security_guard/modules/home/view/home_view.dart';
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/modules/profile/Profile_screen.dart';
import 'package:security_guard/shared/widgets/bottomnavigation/navigation_controller.dart';

class BottomNavBarWidget extends StatelessWidget {
  BottomNavBarWidget({super.key});

  final BottomNavController controller = Get.put(BottomNavController());

  final List<Widget> screens = [
    HomeView(),
    GuardAttendanceScreen(),
    PatrolCheckInScreen(),
    IncidentReportScreen(),
    ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> items = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Attendance'),
    BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Patrol'),
    BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: 'Report'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
         
          body: screens[controller.currentIndex.value],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTab,
            selectedItemColor: AppColors.background,
            unselectedItemColor:  Colors.grey,
            items: items,
            type: BottomNavigationBarType.fixed,
            backgroundColor:AppColors.primary ,
          ),
        ));
  }
}
