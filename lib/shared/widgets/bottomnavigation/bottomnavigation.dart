import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:security_guard/modules/attandance/GuardAttendanceScreen.dart';
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';
import 'package:security_guard/modules/petrol/views/patrol_check_in_view.dart';
import 'package:security_guard/modules/profile/Profile_screen.dart';

import 'package:get/get.dart'; // Add this import if not already present

class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;
}

final BottomNavController controller = Get.put(BottomNavController());

Widget buildBottomNavBar() {
  return Obx(
    () => BottomNavigationBar(
      currentIndex: controller.selectedIndex.value,
      onTap: (index) {
        controller.selectedIndex.value = index;
        switch (index) {
          case 0:
            break;
          case 1:
            Get.to(() => PatrolCheckInScreen());
            break;
          case 2:
            Get.to(() => IncidentReportScreen());
            break;
          case 3:
            Get.to(() => GuardAttendanceScreen());
            break;
          case 4:
            Get.to(() => ProfileScreen());
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF1E3A8A),
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Patrol'),
        BottomNavigationBarItem(
          icon: Icon(Icons.error_outline),
          label: 'Issues',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}
