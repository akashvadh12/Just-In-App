import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:security_guard/modules/petrol/controllers/patrol_controller.dart';

class PatrolCheckInScreen extends StatelessWidget {
  final controller = Get.put(PatrolCheckInController());

  PatrolCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🛡️ Patrol Module'),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          titleTextStyle: AppTextStyles.heading.copyWith(
            color: AppColors.whiteColor,
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.whiteColor,
            labelColor: AppColors.whiteColor,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.track_changes),
                text: 'TRACKER',
              ),
              Tab(
                icon: Icon(Icons.map),
                text: 'MAP',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTrackerTab(),
            _buildMapTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerTab() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshPatrolLocations(),
      child: Column(
        children: [
          // Current step progress
          Obx(() => controller.currentPatrolLocation.value != null
              ? _buildStepProgress()
              : const SizedBox.shrink()),
          
          Expanded(
            child: Obx(() {
              if (controller.currentPatrolLocation.value == null) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add, color: AppColors.whiteColor),
          label: Text(
            '➕ Add Manual Patrol',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
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
  final isCompleted = controller.completedPatrols.contains(location.locationId);
  final isNext = controller.getNextPatrolIndex() == index;
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Card(
      elevation: isNext ? 4 : 2,
      color: isCompleted 
          ? AppColors.greenColor.withOpacity(0.1)
          : isNext 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.whiteColor,
      child: ListTile(
        onTap: isCompleted ? null : () => controller.startPatrolForLocation(location),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted 
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

// ...existing code...

  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.whiteColor,
      child: Column(
        children: [
          // Step indicator
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressStep(1, '📍', 'Verify', controller.currentStep.value >= 1),
              if (!controller.isManualPatrol.value) 
                _buildProgressStep(2, '📷', 'QR Scan', controller.currentStep.value >= 2),
              _buildProgressStep(
                controller.isManualPatrol.value ? 2 : 3, 
                '📸', 
                'Photo', 
                controller.currentStep.value >= (controller.isManualPatrol.value ? 2 : 3)
              ),
              _buildProgressStep(
                controller.isManualPatrol.value ? 3 : 4, 
                '📝', 
                'Notes', 
                controller.currentStep.value >= (controller.isManualPatrol.value ? 3 : 4)
              ),
              _buildProgressStep(
                controller.isManualPatrol.value ? 4 : 5, 
                '✅', 
                'Submit', 
                controller.currentStep.value >= (controller.isManualPatrol.value ? 4 : 5)
              ),
            ],
          )),
          const SizedBox(height: 8),
          Obx(() => Text(
            'Step ${controller.currentStep.value} of ${controller.isManualPatrol.value ? 4 : 5}: ${controller.getCurrentStepTitle()}',
            style: AppTextStyles.hint,
          )),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String emoji, String label, bool isCompleted) {
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
            child: isCompleted
                ? const Icon(Icons.check, color: AppColors.whiteColor)
                : Text(
                    emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.hint.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildStepWisePatrol() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          switch (controller.currentStep.value) {
            case 1:
              return _buildVerifyLocationStep();
            case 2:
              return controller.isManualPatrol.value 
                  ? _buildPhotoStep() 
                  : _buildQRScanStep();
            case 3:
              return controller.isManualPatrol.value 
                  ? _buildNotesStep() 
                  : _buildPhotoStep();
            case 4:
              return controller.isManualPatrol.value 
                  ? _buildSubmitStep() 
                  : _buildNotesStep();
            case 5:
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
        Text(
          '📍 Verify Location',
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: 8),
        Text(
          'Please ensure you are at the correct location by matching GPS coordinates.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),
        
        // Mini Map
        SizedBox(
          height: 200,
          child: _buildMiniMap(),
        ),
        
        const SizedBox(height: 16),
        
        // GPS Coordinates
        Obx(() => Container(
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
        )),
        
        const SizedBox(height: 24),
        
        // Continue Button
        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.isLocationVerified.value 
                ? () => controller.goToNextStep()
                : () => controller.verifyLocation(),
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.isLocationVerified.value 
                  ? AppColors.greenColor 
                  : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              controller.isLocationVerified.value ? 'Continue' : 'Verify Location',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
            ),
          ),
        )),
        const SizedBox(height: 24),

         SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              controller.cancelCurrentPatrol();
              controller.currentStep.value = 0; // Reset step
              controller.isManualPatrol.value = false; // Reset manual patrol flag
              controller.currentPatrolLocation.value = null; // Clear current location

            } ,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
               'Back' ,
              style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRScanStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📷 Scan QR Code',
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: 8),
        Text(
          'Scan the QR code at the patrol point to confirm your presence.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 24),
        
        Center(
          child: GestureDetector(
            onTap: () => controller.openQRScanner(),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Tap to Scan QR Code',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.isQRScanned.value 
                ? () => controller.goToNextStep()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.greyColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Continue',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📸 Upload Photo',
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: 8),
        Text(
          'Take a photo to document your patrol visit.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),
        
        _buildPhotoSection(),
        
        const SizedBox(height: 24),
        
        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.capturedImage.value != null 
                ? () => controller.goToNextStep()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.greyColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Continue',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildNotesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 Add Patrol Notes',
          style: AppTextStyles.heading,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Continue',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
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
        Text(
          '✅ Submit Report',
          style: AppTextStyles.heading,
        ),
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
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 Location: ${controller.currentPatrolLocation.value?.locationName ?? "Manual Patrol"}'),
                  Text('✅ Verified: ${controller.isLocationVerified.value ? "Yes" : "No"}'),
                  if (!controller.isManualPatrol.value)
                    Text('📷 QR Scanned: ${controller.isQRScanned.value ? "Yes" : "No"}'),
                  Text('📸 Photo: ${controller.capturedImage.value != null ? "Captured" : "None"}'),
                  Text('📝 Notes: ${controller.notes.value.isNotEmpty ? controller.notes.value : "None"}'),
                ],
              )),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Submit Patrol Report',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
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
              style: AppTextStyles.subtitle.copyWith(color: AppColors.greyColor),
            ),
          ),
        ),
      ],
    );
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

  Widget _buildMapTab() {
    return Obx(() => FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: controller.currentLatLng.value ?? const LatLng(0, 0),
        initialZoom: 14,
        onMapReady: controller.onMapReady,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'com.example.security_guard',
        ),
        MarkerLayer(
          markers: [
            // Current location
            if (controller.currentLatLng.value != null)
              Marker(
                point: controller.currentLatLng.value!,
                width: 50,
                height: 50,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            // Patrol locations
            ...controller.patrolLocations.map((location) {
              final isCompleted = controller.completedPatrols.contains(location.locationId);
              return Marker(
                point: LatLng(location.latitude, location.longitude),
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.greenColor : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.location_on,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    ));
  }

  Widget _buildPhotoSection() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: controller.capturedImage.value != null
                  ? Colors.transparent
                  : const Color(0xFF222831),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: controller.capturedImage.value != null
                ? Image.file(
                    controller.capturedImage.value!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : const Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.greyColor,
                      size: 48,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                  color: controller.isFlashOn.value 
                      ? AppColors.primary 
                      : AppColors.greyColor,
                ),
                onPressed: () => controller.toggleFlash(),
              ),
              GestureDetector(
                onTap: () => controller.takePicture(),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.whiteColor,
                    size: 30,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.greyColor),
                onPressed: () => controller.retakePhoto(),
              ),
            ],
          ),
        ],
      ),
    ));
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