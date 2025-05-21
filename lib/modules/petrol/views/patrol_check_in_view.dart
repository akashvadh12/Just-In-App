import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:security_guard/modules/petrol/controllers/patrol_controller.dart';

class PatrolCheckInScreen extends StatelessWidget {
  final controller = Get.put(PatrolCheckInController());

  PatrolCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrol Check-in'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading.copyWith(
          color: AppColors.whiteColor,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProgressBar(),
            _buildMapView(),
            _buildLocationOptions(),
            _buildVerificationSection(),
            _buildPhotoSection(),
            _buildNotesSection(),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.whiteColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildProgressStep(1, 'Location', controller.currentStep.value >= 1),
          _buildProgressStep(2, 'Verify', controller.currentStep.value >= 2),
          _buildProgressStep(3, 'Photo', controller.currentStep.value >= 3),
          _buildProgressStep(4, 'Submit', controller.currentStep.value >= 4),
        ],
      ),
    ));
  }

  Widget _buildProgressStep(int step, String label, bool isCompleted) {
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
                    : Text(
                      step.toString(),
                      style: AppTextStyles.body.copyWith(
                        color:
                            isCompleted
                                ? AppColors.whiteColor
                                : AppColors.greyColor,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.subtitle),
      ],
    );
  }

  Widget _buildMapView() {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          Obx(() {
            final latLng = controller.currentLatLng.value;
            return latLng == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                  mapController: controller.mapController,
                  options: MapOptions(
                    initialCenter: latLng,
                    initialZoom: 16,
                    onMapReady: controller.onMapReady,
                    onTap:
                        (tapPosition, point) =>
                            controller.updateLocationFromTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.security_guard',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: latLng,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        // Add markers for selected location if any
                        if (controller.selectedLocation.value != null &&
                            controller.locationCoordinates[controller.selectedLocation.value] != null)
                          Marker(
                            point: controller.locationCoordinates[controller.selectedLocation.value]!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.place,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
          }),
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              onPressed: () => controller.fetchLocation(),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => controller.openQRScanner(),
            child: _buildLocationOption(
              Icons.qr_code_scanner,
              'Scan QR Code',
              'Scan point marker',
            ),
          ),
          GestureDetector(
            onTap: () => controller.showLocationSelectionDialog(),
            child: _buildLocationOption(
              Icons.location_on,
              'Manual Select',
              'Choose from list',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOption(IconData icon, String title, String subtitle) {
    return Container(
      width: 170,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.whiteColor),
          ),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.subtitle),
          Text(subtitle, style: AppTextStyles.hint),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Obx(() => InkWell(
      onTap: () => controller.verifyLocation(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: controller.isLocationVerified.value 
              ? AppColors.greenColor.withOpacity(0.1) 
              : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(8),
          border: controller.isLocationVerified.value
              ? Border.all(color: AppColors.greenColor, width: 1)
              : null,
        ),
        child: ListTile(
          leading: controller.isVerifying.value
              ? SizedBox(
                  width: 24, 
                  height: 24, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : Icon(
                  controller.isLocationVerified.value
                      ? Icons.check_circle
                      : Icons.gps_fixed,
                  color: controller.isLocationVerified.value
                      ? AppColors.greenColor
                      : AppColors.primary,
                ),
          title: Text('Verify Location'),
          subtitle: Text(
            controller.isLocationVerified.value
                ? 'Location verified'
                : controller.selectedLocation.value != null
                    ? 'Check geo-fence for ${controller.selectedLocation.value}'
                    : 'Check geo-fence',
          ),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    ));
  }

  Widget _buildPhotoSection() {
    return Obx(() => Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
        maxLines: 3,
        onChanged: (value) => controller.notes.value = value,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: ElevatedButton(
        onPressed: controller.isLocationVerified.value && controller.capturedImage.value != null
            ? () => controller.submitReport()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.greyColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Submit Patrol Report',
          style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor),
        ),
      ),
    ));
  }
}