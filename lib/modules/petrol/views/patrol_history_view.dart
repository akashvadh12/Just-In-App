// patrol_history_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/petrol/controllers/patrol_history_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PatrolHistoryScreen extends StatelessWidget {
  const PatrolHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PatrolHistoryController());

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('📋 Patrol History'),
      //   backgroundColor: AppColors.primary,
      //   centerTitle: true,
      //   titleTextStyle: AppTextStyles.heading.copyWith(
      //     color: AppColors.whiteColor,
      //   ),
      //   actions: [
      //     IconButton(
      //       onPressed: () => controller.selectDateRange(),
      //       icon: const Icon(Icons.date_range, color: AppColors.whiteColor),
      //     ),
      //   ],
      // ),
      body: Column(
        children: [
          _buildDateRangeHeader(controller),
          Expanded(child: _buildHistoryList(controller)),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader(PatrolHistoryController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () => Text(
              'From: ${controller.formatDate(controller.startDate.value)}',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Obx(
            () => Text(
              'To: ${controller.formatDate(controller.endDate.value)}',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => controller.selectDateRange(),
            icon: const Icon(Icons.date_range, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(PatrolHistoryController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchPatrolHistory(),
      child: Obx(() {
        if (controller.isLoadingHistory.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading patrol history...'),
              ],
            ),
          );
        }

        if (controller.historyList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 64,
                  color: AppColors.greyColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No patrol history found',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.greyColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different date range',
                  style: AppTextStyles.hint,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.selectDateRange(),
                  icon: const Icon(Icons.date_range),
                  label: const Text('Select Date Range'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.whiteColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.historyList.length,
          itemBuilder: (context, index) {
            final history = controller.historyList[index];
            return _buildHistoryCard(history, controller);
          },
        );
      }),
    );
  }

  Widget _buildHistoryCard(
    PatrolHistoryItem history,
    PatrolHistoryController controller,
  ) {
    final duration = history.endTime.difference(history.startTime);
    final durationText = '${duration.inHours}h ${duration.inMinutes % 60}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        color: AppColors.background,
        // history.status
        //     ? AppColors.greenColor
        //     : AppColors.lightGrey,
        child: InkWell(
          onTap: () {
            Get.to(() => PatrolHistoryDetailScreen(logID: history.logID));
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Log ID: ${history.logID}',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            history.status
                                ? AppColors.greenColor
                                : AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        history.status ? 'Completed' : 'Incomplete',
                        style: AppTextStyles.hint.copyWith(
                          color: AppColors.whiteColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.greyColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Start: ${controller.formatDateTime(history.startTime)}',
                      style: AppTextStyles.hint,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_off, size: 16, color: AppColors.greyColor),
                    const SizedBox(width: 4),
                    Text(
                      'End: ${controller.formatDateTime(history.endTime)}',
                      style: AppTextStyles.hint,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timelapse, size: 16, color: AppColors.greyColor),
                    const SizedBox(width: 4),
                    Text('Duration: $durationText', style: AppTextStyles.hint),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visited: ${history.visitedPoll} / ${history.totalPoll ?? 'N/A'}',
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: AppTextStyles.hint.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
                if (history.remarks.isNotEmpty &&
                    history.remarks != 'Unknown Place')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.greyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: AppColors.greyColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Remarks: ${history.remarks}',
                              style: AppTextStyles.hint.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// patrol_history_detail_screen.dart

class PatrolHistoryDetailScreen extends StatelessWidget {
  final String logID;

  const PatrolHistoryDetailScreen({Key? key, required this.logID})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PatrolHistoryController>();

    // Fetch details when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchHistoryDetails(logID);
    });

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Log ID: $logID'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        titleTextStyle: AppTextStyles.subtitle.copyWith(
          color: AppColors.whiteColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingDetails.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading patrol details...'),
              ],
            ),
          );
        }

        if (controller.historyDetails.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.greyColor),
                const SizedBox(height: 16),
                Text(
                  'No details found for this patrol',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.greyColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.historyDetails.length,
          itemBuilder: (context, index) {
            final detail = controller.historyDetails[index];
            return _buildDetailCard(detail, index + 1);
          },
        );
      }),
    );
  }

  Widget _buildDetailCard(PatrolHistoryDetail detail, int stepNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        color: detail.status ? AppColors.lightGrey : AppColors.lightGrey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          detail.status
                              ? AppColors.greenColor
                              : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        stepNumber.toString(),
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.locationName,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'ID: ${detail.locationId}',
                          style: AppTextStyles.hint.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          detail.status
                              ? AppColors.greenColor
                              : AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      detail.status ? 'Visited' : 'Not Visited',
                      style: AppTextStyles.hint.copyWith(
                        color: AppColors.whiteColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location coordinates
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.greyColor),
                  const SizedBox(width: 4),
                  Text(
                    'Lat: ${detail.latitude.toStringAsFixed(6)}, Lng: ${detail.longitude.toStringAsFixed(6)}',
                    style: AppTextStyles.hint,
                  ),
                ],
              ),

              // Visit time
              if (detail.visitTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.greyColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Visit Time: ${detail.visitTime}',
                      style: AppTextStyles.hint,
                    ),
                  ],
                ),
              ],

              // Notes
              if (detail.notes != null && detail.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.greyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: AppColors.greyColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Notes: ${detail.notes}',
                          style: AppTextStyles.hint.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Selfie
              // if (detail.selfie != null && detail.selfie!.isNotEmpty) ...[
              //   const SizedBox(height: 12),
              //   Text(
              //     'Selfie:',
              //     style: AppTextStyles.subtitle.copyWith(
              //       fontWeight: FontWeight.w600,
              //       fontSize: 14,
              //     ),
              //   ),
              //   const SizedBox(height: 8),
              //   ClipRRect(
              //     borderRadius: BorderRadius.circular(8),
              //     child: CachedNetworkImage(
              //       imageUrl: detail.selfie!,
              //       height: 150,
              //       width: double.infinity,
              //       fit: BoxFit.cover,
              //       placeholder:
              //           (context, url) => Container(
              //             height: 150,
              //             color: AppColors.greyColor.withOpacity(0.3),
              //             child: const Center(
              //               child: CircularProgressIndicator(),
              //             ),
              //           ),
              //       errorWidget:
              //           (context, url, error) => Container(
              //             height: 150,
              //             color: AppColors.greyColor.withOpacity(0.3),
              //             child: const Center(
              //               child: Icon(Icons.error, color: AppColors.error),
              //             ),
              //           ),
              //     ),
              //   ),
              // ],

              // Additional images
              if (detail.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Selfie',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: detail.images.length,
                    itemBuilder: (context, imgIndex) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: detail.images[imgIndex],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  height: 100,
                                  width: 100,
                                  color: AppColors.greyColor.withOpacity(0.3),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  height: 100,
                                  width: 100,
                                  color: AppColors.greyColor.withOpacity(0.3),
                                  child: const Center(
                                    child: Icon(
                                      Icons.error,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
