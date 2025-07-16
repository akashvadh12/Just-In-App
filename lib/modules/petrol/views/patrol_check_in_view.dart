import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:security_guard/modules/petrol/controllers/patrol_controller.dart';
import 'package:security_guard/modules/petrol/views/animated_qr_scanner.dart';
import 'package:security_guard/modules/petrol/views/patrol_history_view.dart';
import 'package:security_guard/modules/petrol/views/add_manual_patrol_screen.dart';
import 'package:security_guard/modules/profile/controller/profileController/profilecontroller.dart';

class PatrolCheckInScreen extends StatefulWidget {
  const PatrolCheckInScreen({Key? key}) : super(key: key);

  @override
  State<PatrolCheckInScreen> createState() => _PatrolCheckInScreenState();
}

class _PatrolCheckInScreenState extends State<PatrolCheckInScreen>
    with TickerProviderStateMixin {
  late final TabController _outerTabController;
  late final TabController _innerTabController;
  final controller = Get.put(PatrolCheckInController());
  ProfileController profileController = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    _outerTabController = TabController(length: 2, vsync: this);
    _innerTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _outerTabController.dispose();
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ Start Patrolling'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading.copyWith(
          color: AppColors.whiteColor,
        ),
        bottom: TabBar(
          controller: _outerTabController,
          indicatorColor: AppColors.whiteColor,
          labelColor: AppColors.whiteColor,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.track_changes), text: 'Tracker'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _outerTabController,
        children: [_buildTrackerTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildTrackerTab() {
    return Column(
      children: [
        TabBar(
          controller: _innerTabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Patrols'),
            Tab(text: 'Scan QR'),
            Tab(text: 'Stop Patrol'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTabController,
            children: [
              _buildAddManualPatrolTab(),
              _buildQRScanTab(),
              _buildStopPatrolTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return PatrolHistoryScreen();
  }

  Widget _buildAddManualPatrolTab() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshPatrolLocations(),
      child: Column(
        children: [
          Obx(
            () =>
                controller.currentPatrolLocation.value != null ||
                        controller.isManualPatrol.value
                    ? _buildStepProgress()
                    : const SizedBox.shrink(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.currentPatrolLocation.value == null &&
                  !controller.isManualPatrol.value) {
                return _buildPatrolLocationsList();
              } else {
                return _buildStepWisePatrol();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanTab() {
    return _buildQRScan();
  }

  // Widget _buildStopPatrolTab() {
  //   return Center(
  //     child: ElevatedButton(
  //       onPressed: () {
  //         controller.cancelCurrentPatrol();
  //       },
  //       child: const Text('Stop Patrol'),
  //     ),
  //   );
  // }

  // Enhanced Stop Patrol UI
Widget _buildStopPatrolTab() {
  return Obx(() {
    final user = profileController.userModel.value;

    // Safely check if logId is null or empty
    if (user?.logId == null || user!.logId!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Patrol',
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'You are not currently checked in to any patrol.\nPlease start a patrol to see stop options here.',
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  goToFirstInnerTab(); // Assume this takes user to start patrol
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Start Patrol'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon and title
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stop_circle,
              size: 64,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Stop Current Patrol',
            style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Are you sure you want to end the current patrol session?',
            textAlign: TextAlign.center,
            style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),

          // Remarks input field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: controller.remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add remarks (optional)',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.remarksController.clear();
                    goToFirstInnerTab();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.stopPatrol(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Stop Patrol',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status display
          Obx(() {
            if (controller.lastPatrolStatus.isNotEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: controller.lastPatrolStatus.contains('successful')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.lastPatrolStatus.contains('successful')
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  controller.lastPatrolStatus.value,
                  style: TextStyle(
                    color: controller.lastPatrolStatus.contains('successful')
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  });
}


  Widget _buildPatrolLocationsList() {
    return Column(
      children: [
        // Add Manual Patrol Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to the new AddManualPatrolScreen
              print(
                'Navigating to AddManualPatrolScreen ${profileController.userModel.value?.logId}',
              );
              // if (profileController.userModel.value == null) return;

              if (profileController.userModel.value!.attendanceStatus ==
                  "Not Marked") {
                Get.snackbar(
                  'Reminder',
                  'Kindly mark your attendance to proceed.',
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );

                return;
              }
              if (profileController.userModel.value!.logId == null ||
                  profileController.userModel.value!.logId!.isEmpty) {
                Get.snackbar(
                  "No Patrol Log",
                  "Please start a patrol first.",
                  backgroundColor: Colors.orange.shade600,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(12),
                  borderRadius: 10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  icon: const Icon(Icons.warning, color: Colors.white),
                  shouldIconPulse: false,
                  duration: const Duration(seconds: 2),
                  barBlur: 10,
                  overlayBlur: 2,
                );
                return;
              }
              Get.to(() => const AddManualPatrolScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // icon: const Icon(Icons.add, color: AppColors.whiteColor),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: AppColors.whiteColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Add Manual Patrol',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.whiteColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Loading indicator or Patrol Locations List
        Expanded(
          child: Obx(() {
            if (controller.isLoadingLocations.value) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading patrol locations...'),
                  ],
                ),
              );
            }

            if (controller.patrolLocations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: AppColors.greyColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No patrol locations available',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.greyColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.refreshPatrolLocations(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: controller.patrolLocations.length,
              itemBuilder: (context, index) {
                final location = controller.patrolLocations[index];
                return _buildPatrolLocationCard(location, index);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPatrolLocationCard(PatrolLocation location, int index) {
    final isCompleted = controller.completedPatrols.contains(
      location.locationId,
    );
    final isNext = controller.getNextPatrolIndex() == index;
    final isLast = index == controller.patrolLocations.length - 1;
    final isFirst = index == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Top connecting line (skip for first item)
                  
                            
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 16,
                      color:
                          isCompleted
                              ? AppColors.greenColor
                              : AppColors.greyColor.withOpacity(0.5),
                    ),
                  // Circle indicator
                  Container(
                    width: 40,
                    height: 40,
                    margin: isFirst? const EdgeInsets.only(top: 16): const EdgeInsets.only(top: 0),
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? AppColors.greenColor
                              : isNext
                              ? AppColors.primary
                              : AppColors.greyColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child:
                          isCompleted
                              ? Icon(
                                Icons.check,
                                color: AppColors.whiteColor,
                                size: 20,
                              )
                              : Text(
                                '${index + 1}',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppColors.whiteColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  // Bottom connecting line (skip for last item)
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 16,
                      color:
                          isCompleted
                              ? AppColors.greenColor
                              : AppColors.greyColor.withOpacity(0.5),
                    )
                  else
                    const SizedBox(height: 0), // No space for last item
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 12, bottom: 8),
                child: Card(
                  elevation: isNext ? 4 : 1,
                  color:
                      isCompleted
                          ? AppColors.whiteColor
                          : isNext
                          ? AppColors.primary
                          : AppColors.whiteColor,
                  child: ListTile(
                    onTap:
                        isCompleted
                            ? null
                            : () => controller.startPatrolForLocation(location),
                    title: Text(
                      location.locationName,
                      style: AppTextStyles.subtitle.copyWith(
                        color:
                            isCompleted
                                ? AppColors.greenColor
                                : isNext
                                ? AppColors.whiteColor
                                : AppColors.blackColor,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isNext)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NEXT',
                              style: AppTextStyles.hint.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isCompleted)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.greenColor,
                          )
                        else
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.greyColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.whiteColor,
      child: Column(
        children: [
          // Step indicator
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProgressStep(
                  1,
                  '📍',
                  'Verify',
                  controller.currentStep.value >= 1,
                ),

                _buildProgressStep(
                  controller.isManualPatrol.value ? 2 : 3,
                  '📸',
                  'Photo',
                  controller.currentStep.value >=
                      (controller.isManualPatrol.value ? 2 : 3),
                ),
                _buildProgressStep(
                  controller.isManualPatrol.value ? 3 : 4,
                  '📝',
                  'Notes',
                  controller.currentStep.value >=
                      (controller.isManualPatrol.value ? 3 : 4),
                ),
                _buildProgressStep(
                  controller.isManualPatrol.value ? 4 : 5,
                  '✅',
                  'Submit',
                  controller.currentStep.value >=
                      (controller.isManualPatrol.value ? 4 : 5),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 8),
          // Obx(
          //   () => Text(
          //     'Step ${controller.currentStep.value} of ${controller.isManualPatrol.value ? 4 : 5}: ${controller.getCurrentStepTitle()}',
          //     style: AppTextStyles.hint,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
    int step,
    String emoji,
    String label,
    bool isCompleted,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primary : AppColors.lightGrey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child:
                isCompleted
                    ? const Icon(Icons.check, color: AppColors.whiteColor)
                    : Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.hint.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildStepWisePatrol() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          switch (controller.currentStep.value) {
            case 1:
              return _buildVerifyLocationStep();
            case 2:
              return _buildPhotoStep();
            case 3:
              return _buildNotesStep();
            case 4:
              return _buildSubmitStep();
            default:
              return _buildVerifyLocationStep();
          }
        }),
      ),
    );
  }

  Widget _buildVerifyLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text('📍 Verify Location', style: AppTextStyles.heading)),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Ensure you are at the correct location by matching GPS coordinates.',
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),

        // Compact Mini Map
        SizedBox(height: 140, child: _buildMiniMap()),

        const SizedBox(height: 12),

        // GPS Coordinates - More compact
        // Obx(
        //   () => Container(
        //     padding: const EdgeInsets.all(12),
        //     decoration: BoxDecoration(
        //       color: AppColors.lightGrey,
        //       borderRadius: BorderRadius.circular(6),
        //     ),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text(
        //           'Current: ${controller.getCurrentGPSString()}',
        //           style: TextStyle(fontSize: 12),
        //         ),
        //         const SizedBox(height: 2),
        //         Text(
        //           'Target: ${controller.getTargetGPSString()}',
        //           style: TextStyle(fontSize: 12),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        const SizedBox(height: 16),

        // Buttons Row - Side by side to save vertical space
        Column(
          children: [
            // Verify/Continue Button - Primary Action
            Obx(
              () =>
                  controller.isVerifyingLocation.value
                      ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            // const SizedBox(height: 8),
                            // Text(
                            //   'Verifying your location...',
                            //   style: AppTextStyles.subtitle.copyWith(
                            //     color: AppColors.primary,
                            //     fontSize: 14,
                            //   ),
                            // ),
                          ],
                        ),
                      )
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              controller.isLocationVerified.value
                                  ? () => controller.goToNextStep()
                                  : () => controller.verifyLocation(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                controller.isLocationVerified.value
                                    ? AppColors.greenColor
                                    : AppColors.primary,
                            foregroundColor: AppColors.whiteColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation:
                                controller.isLocationVerified.value ? 2 : 4,
                          ),
                          icon: Icon(
                            controller.isLocationVerified.value
                                ? Icons.arrow_forward_rounded
                                : Icons.location_searching_rounded,
                            size: 20,
                          ),
                          label: Text(
                            controller.isLocationVerified.value
                                ? 'Continue to Next Step'
                                : 'Verify My Location',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.whiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
            ),

            const SizedBox(height: 16),

            // Status Message (Optional feedback)
            Obx(
              () =>
                  controller.isLocationVerified.value
                      ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.greenColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.greenColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location verified successfully!',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.greenColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // Back Button - Secondary Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Show confirmation dialog for better UX
                  // _showCancelConfirmation();
                  controller.cancelCurrentPatrol();
                  controller.currentStep.value = 0;
                  controller.isManualPatrol.value = false;
                  controller.currentPatrolLocation.value = null;
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: Text(
                  'Cancel Patrol',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Add this method to your controller or widget
  void _showCancelConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cancel Patrol?',
              style: AppTextStyles.heading.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel your current patrol?',
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Keep Patrol',
                    style: AppTextStyles.subtitle.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    controller.cancelCurrentPatrol();
                    controller.currentStep.value = 0;
                    controller.isManualPatrol.value = false;
                    controller.currentPatrolLocation.value = null;

                    // Show success message
                    Get.snackbar(
                      'Patrol Canceled',
                      'Your patrol has been canceled successfully',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green.shade100,
                      colorText: Colors.green.shade800,
                      icon: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                      ),
                      duration: const Duration(seconds: 2),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel Patrol',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Widget _buildQRScanStep() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         '📷 Scan QR Code',
  //         style: AppTextStyles.heading,
  //       ),
  //       const SizedBox(height: 8),
  //       Text(
  //         'Scan the QR code at the patrol point to confirm your presence.',
  //         style: AppTextStyles.body,
  //       ),
  //       const SizedBox(height: 24),

  //       Center(
  //         child: GestureDetector(
  //           onTap: () => controller.openQRScanner(),
  //           child: Container(
  //             width: 200,
  //             height: 200,
  //             decoration: BoxDecoration(
  //               color: AppColors.lightGrey,
  //               borderRadius: BorderRadius.circular(12),
  //               border: Border.all(color: AppColors.primary, width: 2),
  //             ),
  //             child: const Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
  //                 SizedBox(height: 16),
  //                 Text(
  //                   'Tap to Scan QR Code',
  //                   style: TextStyle(
  //                     color: AppColors.primary,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),

  //       const SizedBox(height: 24),

  //       Obx(() => SizedBox(
  //         width: double.infinity,
  //         child: ElevatedButton(
  //           onPressed: controller.isQRScanned.value
  //               ? () => controller.goToNextStep()
  //               : null,
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColors.primary,
  //             disabledBackgroundColor: AppColors.greyColor,
  //             padding: const EdgeInsets.symmetric(vertical: 16),
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //           ),
  //           child: Text(
  //             'Continue',
  //             style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
  //           ),
  //         ),
  //       )),
  //     ],
  //   );
  // }

  void goToFirstInnerTab() {
    _innerTabController.index = 0;
    _innerTabController.animateTo(0);
    controller.isQRMatched.value = false;
  }

  Widget _buildQRScan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text('Scan QR Code', style: AppTextStyles.heading),
          ),
        ),
        const SizedBox(height: 24),
        QRScannerWidget(
          onTap: () => controller.openQRScanner(onSuccess: goToFirstInnerTab),
          controller: controller,
        ),
      ],
    );
  }

  Widget _buildNotesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text('📝 Add Patrol Notes', style: AppTextStyles.heading),
        ),
        const SizedBox(height: 8),
        Text(
          'Add any observations or notes about your patrol (optional).',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),

        _buildNotesSection(),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => controller.goToNextStep(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Continue',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text('✅ Submit Report', style: AppTextStyles.heading)),
        const SizedBox(height: 8),
        Text(
          'Review your patrol information and submit the report.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),

        // Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patrol Summary', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 Location: ${controller.currentPatrolLocation.value?.locationName ?? "Manual Patrol"}',
                    ),
                    // Text(
                    //   '✅ Verified: ${controller.isLocationVerified.value ? "Yes" : "No"}',
                    // ),
                    if (!controller.isManualPatrol.value)
                      // Text(
                      //   '📷 QR Scanned: ${controller.isQRScanned.value ? "Yes" : "No"}',
                      // ),
                      Text(
                        '📸 Photo: ${controller.capturedImage.value != null ? "Captured" : "None"}',
                      ),
                    Text(
                      '📝 Notes: ${controller.notes.value.isNotEmpty ? controller.notes.value : "None"}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => controller.submitPatrolReport(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Submit Patrol Report',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => controller.cancelCurrentPatrol(),
            child: Text(
              'Cancel Patrol',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.greyColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final isTablet = screenWidth > 600;

        // Responsive spacing
        final double headingSpacing = isTablet ? 10 : 6;
        final double contentSpacing = isTablet ? 16 : 12;
        final double buttonSpacing = isTablet ? 24 : 16;

        // Responsive font sizes
        final double headingFontSize = isTablet ? 20 : 18;
        final double bodyFontSize = isTablet ? 15 : 13;
        final double buttonFontSize = isTablet ? 16 : 14;

        // Responsive padding
        final double buttonVerticalPadding = isTablet ? 16 : 12;
        final double borderRadius = isTablet ? 10 : 6;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with responsive sizing
            Center(
              child: Text(
                '📸 Upload Photo',
                style: AppTextStyles.heading.copyWith(
                  fontSize: headingFontSize,
                ),
              ),
            ),
            SizedBox(height: headingSpacing),

            // Description with responsive text
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 16),
                child: Text(
                  'Take a photo to document your patrol visit.',
                  style: AppTextStyles.body.copyWith(fontSize: bodyFontSize),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(height: contentSpacing),

            // Photo card with responsive container
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.4, // Max 40% of screen height
                minHeight: isTablet ? 200 : 150,
              ),
              child: _buildPhotoCard(),
            ),

            SizedBox(height: buttonSpacing),

            // Continue button with responsive styling
            Obx(
              () => Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 400 : double.infinity,
                ),
                child: Center(
                  child: SizedBox(
                    width: isTablet ? 300 : double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          controller.capturedImage.value != null
                              ? () => controller.goToNextStep()
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.greyColor,
                        padding: EdgeInsets.symmetric(
                          vertical: buttonVerticalPadding,
                          horizontal: isTablet ? 24 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        elevation:
                            controller.capturedImage.value != null ? 2 : 0,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.capturedImage.value != null) ...[
                            Icon(
                              Icons.check_circle,
                              color: AppColors.whiteColor,
                              size: isTablet ? 20 : 16,
                            ),
                            SizedBox(width: 8),
                          ],
                          Text(
                            controller.capturedImage.value != null
                                ? 'Continue'
                                : 'Take Photo First',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.whiteColor,
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Additional spacing for better layout
            SizedBox(height: isTablet ? 20 : 12),
          ],
        );
      },
    );
  }

  Widget _buildPhotoCard() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact Header
            Row(
              children: [
                Icon(Icons.camera_alt, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (controller.capturedImage.value != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Compact Photo area
            GestureDetector(
              onTap: () => controller.takePicture(context),
              child: Container(
                width: double.infinity,
                height: 140, // Reduced from 180
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        controller.capturedImage.value != null
                            ? Colors.green
                            : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child:
                      controller.capturedImage.value != null
                          ? Stack(
                            children: [
                              Image.file(
                                controller.capturedImage.value!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Container(
                            color: Colors.grey[50],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 24,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to capture photo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Required for patrol documentation',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                ),
              ),
            ),

            // Compact Retake option
            if (controller.capturedImage.value != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => controller.retakePhoto(),
                  icon: Icon(Icons.refresh, color: AppColors.primary, size: 16),
                  label: Text(
                    'Retake Photo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMiniMap() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey),
      ),
      clipBehavior: Clip.antiAlias,
      child: Obx(() {
        final latLng = controller.currentLatLng.value;
        return latLng == null
            ? const Center(child: CircularProgressIndicator())
            : FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(
                initialCenter: latLng,
                initialZoom: 16,
                onMapReady: controller.onMapReady,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.security_guard',
                ),
                MarkerLayer(
                  markers: [
                    // Current location marker
                    Marker(
                      point: latLng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                    // Target location marker
                    if (controller.currentPatrolLocation.value != null)
                      Marker(
                        point: LatLng(
                          controller.currentPatrolLocation.value!.latitude,
                          controller.currentPatrolLocation.value!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            );
      }),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Add patrol notes (optional)',
          hintStyle: AppTextStyles.hint,
          border: InputBorder.none,
        ),
        maxLines: 5,
        onChanged: (value) => controller.notes.value = value,
      ),
    );
  }
}
