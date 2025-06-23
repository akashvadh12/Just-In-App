import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:security_guard/modules/petrol/controllers/patrol_controller.dart';
import 'package:security_guard/modules/petrol/views/patrol_history_view.dart';

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
                controller.currentPatrolLocation.value != null  || controller.isManualPatrol.value
                    ? _buildStepProgress()
                    : const SizedBox.shrink(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.currentPatrolLocation.value == null && !controller.isManualPatrol.value) {
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
  return Padding(
    padding: const EdgeInsets.all(16.0),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        
        Text(
          'Are you sure you want to end the current patrol session?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              child: Obx(() => ElevatedButton(
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Stop Patrol',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
              )),
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
}

  Widget _buildPatrolLocationsList() {
    return Column(
      children: [
        // Add Manual Patrol Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => controller.addManualPatrol(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // icon: const Icon(Icons.add, color: AppColors.whiteColor),
            label: Text(
              '➕ Add Manual Patrol',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.whiteColor,
              ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: isNext ? 4 : 1,
        color:
            isCompleted
                ? AppColors.greenColor.withOpacity(0.1)
                : isNext
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.whiteColor,
        child: ListTile(
          onTap:
              isCompleted
                  ? null
                  : () => controller.startPatrolForLocation(location),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? AppColors.greenColor
                      : isNext
                      ? AppColors.primary
                      : AppColors.greyColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.location_on,
              color: AppColors.whiteColor,
            ),
          ),
          title: Text(
            location.locationName,
            style: AppTextStyles.subtitle.copyWith(
              color: isCompleted ? AppColors.greenColor : AppColors.blackColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${location.locationId}',
                style: AppTextStyles.hint.copyWith(fontSize: 12),
              ),
              Text(
                '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                style: AppTextStyles.hint,
              ),
              if (location.barcodeUrl.isNotEmpty)
                Text(
                  'QR Code Available',
                  style: AppTextStyles.hint.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
            ],
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEXT',
                    style: AppTextStyles.hint.copyWith(
                      color: AppColors.whiteColor,
                      fontSize: 10,
                    ),
                  ),
                )
              else if (isCompleted)
                const Icon(Icons.check_circle, color: AppColors.greenColor)
              else
                const Icon(Icons.chevron_right, color: AppColors.greyColor),

              // Status indicator
              if (!location.status)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Inactive',
                    style: AppTextStyles.hint.copyWith(
                      color: AppColors.error,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
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
          const SizedBox(height: 8),
          Obx(
            () => Text(
              'Step ${controller.currentStep.value} of ${controller.isManualPatrol.value ? 4 : 5}: ${controller.getCurrentStepTitle()}',
              style: AppTextStyles.hint,
            ),
          ),
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
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isManualPatrol.value && controller.currentStep.value == 2) {
            return _buildManualPatrolStep();
          }
          switch (controller.currentStep.value) {
            case 1:
              return _buildVerifyLocationStep();
            case 2:
              return controller.isManualPatrol.value
                  ? _buildNotesStep()
                  : _buildPhotoStep();
            case 3:
              return controller.isManualPatrol.value
                  ? _buildSubmitStep()
                  : _buildNotesStep();
            case 4:
              return _buildSubmitStep();
            default:
              return _buildVerifyLocationStep();
          }
        }),
      ),
    );
  }

  Widget _buildManualPatrolStep() {
    return Obx(() {
      final TextEditingController locationNameController = TextEditingController(text: controller.notes.value);
      final TextEditingController noteController = TextEditingController();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manual Patrol Check-In', style: AppTextStyles.heading),
          const SizedBox(height: 16),
          TextField(
            controller: locationNameController,
            decoration: const InputDecoration(
              labelText: 'Manual Location Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Current GPS: \\${controller.getCurrentGPSString()}'),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          controller.capturedImage.value == null
              ? ElevatedButton.icon(
                  onPressed: () => controller.takePicture(),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Selfie'),
                )
              : Column(
                  children: [
                    Image.file(controller.capturedImage.value!, height: 120),
                    TextButton(
                      onPressed: () => controller.retakePhoto(),
                      child: const Text('Retake Photo'),
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () async {
                      if (locationNameController.text.trim().isEmpty) {
                        Get.snackbar('Error', 'Please enter a location name');
                        return;
                      }
                      if (controller.capturedImage.value == null) {
                        Get.snackbar('Error', 'Please take a selfie');
                        return;
                      }
                      final latLng = controller.currentLatLng.value;
                      if (latLng == null) {
                        Get.snackbar('Error', 'Current location not available');
                        return;
                      }
                      // final logId = controller.generateLogId();
                      await controller.addManualPatrolApi(
                        manualLocationName: locationNameController.text.trim(),
                        manualLatitude: latLng.latitude,
                        manualLongitude: latLng.longitude,
                        selfie: controller.capturedImage.value!,
                        note: noteController.text.trim(),
                        // logId: logId,
                      );
                    },
              child: controller.isLoading.value
                  ? const CircularProgressIndicator()
                  : const Text('Submit Manual Patrol'),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildVerifyLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📍 Verify Location', style: AppTextStyles.heading),
        const SizedBox(height: 8),
        Text(
          'Please ensure you are at the correct location by matching GPS coordinates.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),

        // Mini Map
        SizedBox(height: 200, child: _buildMiniMap()),

        const SizedBox(height: 16),

        // GPS Coordinates
        Obx(
          () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current GPS: ${controller.getCurrentGPSString()}'),
                Text('Target GPS: ${controller.getTargetGPSString()}'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Continue Button
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  controller.isLocationVerified.value
                      ? () => controller.goToNextStep()
                      : () => controller.verifyLocation(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.isLocationVerified.value
                        ? AppColors.greenColor
                        : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                controller.isLocationVerified.value
                    ? 'Continue'
                    : 'Verify Location',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.whiteColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              controller.cancelCurrentPatrol();
              controller.currentStep.value = 0; // Reset step
              controller.isManualPatrol.value =
                  false; // Reset manual patrol flag
              controller.currentPatrolLocation.value =
                  null; // Clear current location
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Back',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ),
      ],
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
}

  Widget _buildQRScan() {
    return Obx(() {
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
          Center(
            child: GestureDetector(
              onTap: () => controller.openQRScanner(onSuccess: goToFirstInnerTab),
              child: Container(
                width: 280,
                height: 380,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap to Scan QR Code',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (controller.scannedQRData.value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Column(
                          children: [
                            Text(
                              'Scanned Data:',
                              style: AppTextStyles.subtitle,
                            ),
                            Text(
                              controller.scannedQRData.value,
                              style: AppTextStyles.hint,
                            ),
                            if (controller.isQRMatched.value)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Location matched! Patrol started.',
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: AppColors.greenColor,
                                  ),
                                ),
                              ),
                            if (controller.qrScanError.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  controller.qrScanError.value,
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildNotesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📝 Add Patrol Notes', style: AppTextStyles.heading),
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
        Text('✅ Submit Report', style: AppTextStyles.heading),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📸 Upload Photo', style: AppTextStyles.heading),
        const SizedBox(height: 8),
        Text(
          'Take a photo to document your patrol visit.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),

        _buildPhotoCard(),

        const SizedBox(height: 24),

        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  controller.capturedImage.value != null
                      ? () => controller.goToNextStep()
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.greyColor,
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

          
        ),
        SizedBox(height: 16),
         SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              controller.cancelCurrentPatrol();
              controller.currentStep.value = 0; 
              controller.isManualPatrol.value =
                  false; // Reset manual patrol flag
              controller.currentPatrolLocation.value =
                  null; // Clear current location
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Back',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.camera_alt, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (controller.capturedImage.value != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 16),

            // Photo area
            GestureDetector(
              onTap: () => controller.takePicture(),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        controller.capturedImage.value != null
                            ? Colors.green
                            : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      controller.capturedImage.value != null
                          ? Stack(
                            children: [
                              Image.file(
                                controller.capturedImage.value!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
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
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to capture photo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Required for patrol documentation',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                ),
              ),
            ),

            // // Camera controls (only show when no image is captured)
            // if (controller.capturedImage.value == null) ...[
            //   const SizedBox(height: 16),
            //   Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       // Flash toggle
            //       Container(
            //         decoration: BoxDecoration(
            //           color: Colors.grey[100],
            //           borderRadius: BorderRadius.circular(8),
            //         ),
            //         child: IconButton(
            //           icon: Icon(
            //             controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
            //             color: controller.isFlashOn.value
            //                 ? AppColors.primary
            //                 : Colors.grey[600],
            //             size: 20,
            //           ),
            //           onPressed: () => controller.toggleFlash(),
            //         ),
            //       ),
            //       const SizedBox(width: 16),

            //       // Main camera button
            //       GestureDetector(
            //         onTap: () => controller.takePicture(),
            //         child: Container(
            //           width: 60,
            //           height: 60,
            //           decoration: BoxDecoration(
            //             color: AppColors.primary,
            //             shape: BoxShape.circle,
            //             boxShadow: [
            //               BoxShadow(
            //                 color: AppColors.primary.withOpacity(0.3),
            //                 spreadRadius: 0,
            //                 blurRadius: 8,
            //                 offset: const Offset(0, 2),
            //               ),
            //             ],
            //           ),
            //           child: const Icon(
            //             Icons.camera_alt,
            //             color: Colors.white,
            //             size: 28,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ],

            // Retake option (only show when image is captured)
            if (controller.capturedImage.value != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () => controller.retakePhoto(),
                  icon: Icon(Icons.refresh, color: AppColors.primary, size: 18),
                  label: Text(
                    'Retake Photo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
