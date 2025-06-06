import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/attandance/AttendanceHistoryScreen/attendance_history_controller.dart';


class AttendanceHistoryScreen extends StatelessWidget {
  final AttendanceHistoryController controller = Get.put(AttendanceHistoryController());

  AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              switch (controller.selectedTab.value) {
                case 0:
                  return _buildHistoryView();
                case 1:
                  return _buildTodayView();
                case 2:
                  return _buildReportView();
                default:
                  return _buildHistoryView();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.whiteColor,
      child: Obx(() => Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'History', Icons.history),
          ),
          Expanded(
            child: _buildTabButton(1, 'Today', Icons.today),
          ),
          Expanded(
            child: _buildTabButton(2, 'Report', Icons.analytics),
          ),
        ],
      )),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = controller.selectedTab.value == index;
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary: AppColors.greyColor,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.greyColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        _buildMonthSelector(),
        Expanded(
          child: Obx(() {
            if (controller.attendanceRecords.isEmpty) {
              return const Center(
                child: Text('No attendance records found'),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchAttendanceHistory(),
              child: ListView.builder(
                itemCount: controller.attendanceRecords.length,
                itemBuilder: (context, index) {
                  return _buildAttendanceCard(controller.attendanceRecords[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTodayView() {
    return Obx(() {
      final todayData = controller.todayAttendance.value;
      
      if (todayData == null) {
        return const Center(
          child: Text('No attendance data for today'),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchTodayAttendance(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTodayTimeCard(todayData),
              const SizedBox(height: 16),
              if (todayData.records.isNotEmpty) ...[
                Text(
                  'Attendance Records',
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 8),
                ...todayData.records.map((record) => _buildRecordDetailCard(record)),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildReportView() {
    return Column(
      children: [
        _buildDateRangeSelector(),
        Expanded(
          child: Obx(() {
            if (controller.reportRecords.isEmpty) {
              return const Center(
                child: Text('No attendance records found for selected date range'),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchAttendanceReport(),
              child: ListView.builder(
                itemCount: controller.reportRecords.length,
                itemBuilder: (context, index) {
                  return _buildAttendanceCard(controller.reportRecords[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.whiteColor,
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => controller.changeMonth(false),
          ),
          Text(
            DateFormat('MMMM yyyy').format(controller.currentMonth.value),
            style: AppTextStyles.heading,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => controller.changeMonth(true),
          ),
        ],
      )),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.whiteColor,
      child: Obx(() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectFromDate(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.greyColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From', style: AppTextStyles.body),
                    Text(
                      DateFormat('dd/MM/yyyy').format(controller.fromDate.value),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectToDate(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.greyColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To', style: AppTextStyles.body),
                    Text(
                      DateFormat('dd/MM/yyyy').format(controller.toDate.value),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(record.date),
                  style: AppTextStyles.subtitle,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(record.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      color: _getStatusColor(record.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (record.inTime != null || record.outTime != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.greyColor),
                  const SizedBox(width: 8),
                  Text(
                    '${record.inTime ?? '--:--'} - ${record.outTime ?? '--:--'}',
                    style: AppTextStyles.body,
                  ),
                  if (record.duration != null) ...[
                    const Spacer(),
                    Text(
                      record.duration!,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (record.inPhoto != null || record.outPhoto != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (record.inPhoto != null) ...[
                    GestureDetector(
                      onTap: () => _showPhotoDialog(record.inPhoto!, 'Check In Photo'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(record.inPhoto!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (record.outPhoto != null) ...[
                    GestureDetector(
                      onTap: () => _showPhotoDialog(record.outPhoto!, 'Check Out Photo'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(record.outPhoto!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTimeCard(TodayAttendance todayData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Attendance',
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check In', style: AppTextStyles.body),
                    Text(
                      todayData.checkInTime ?? '--:--',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Check Out', style: AppTextStyles.body),
                    Text(
                      todayData.checkOutTime ?? '--:--',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordDetailCard(AttendanceRecordDetail record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(record.selfieUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.type.toUpperCase(),
                  style: AppTextStyles.subtitle.copyWith(
                    color: record.type == 'in' ? AppColors.greenColor : AppColors.error,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(record.timestamp)),
                  style: AppTextStyles.body,
                ),
                Text(
                  'Lat: ${record.latitude}, Lng: ${record.longitude}',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.greenColor;
      case 'absent':
        return AppColors.error;
      case 'late':
        return Colors.orange;
      default:
        return AppColors.greyColor;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('E, MMM d').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _selectFromDate() async {
    final selectedDate = await showDatePicker(
      context: Get.context!,
      initialDate: controller.fromDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (selectedDate != null) {
      controller.setDateRange(selectedDate, controller.toDate.value);
    }
  }

  void _selectToDate() async {
    final selectedDate = await showDatePicker(
      context: Get.context!,
      initialDate: controller.toDate.value,
      firstDate: controller.fromDate.value,
      lastDate: DateTime.now(),
    );
    
    if (selectedDate != null) {
      controller.setDateRange(controller.fromDate.value, selectedDate);
    }
  }

  void _showPhotoDialog(String photoUrl, String title) {
    Get.dialog(
      Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: AppTextStyles.heading),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: Get.height * 0.6,
                maxWidth: Get.width * 0.8,
              ),
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    child: const Center(
                      child: Text('Failed to load image'),
                    ),
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}