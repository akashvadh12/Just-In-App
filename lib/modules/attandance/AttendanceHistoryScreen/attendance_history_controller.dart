import 'package:get/get.dart';

class AttendanceHistoryController extends GetxController {
  var attendanceList = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAttendance();
  }

  void fetchAttendance() {
    // simulate data fetch
    attendanceList.value = ["Monday", "Tuesday", "Wednesday"];
  }
}
