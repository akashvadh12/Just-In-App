import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/petrol/controllers/patrol_controller.dart';

class AddManualPatrolScreen extends StatefulWidget {
  const AddManualPatrolScreen({Key? key}) : super(key: key);

  @override
  State<AddManualPatrolScreen> createState() => _AddManualPatrolScreenState();
}

class _AddManualPatrolScreenState extends State<AddManualPatrolScreen> {
  final PatrolCheckInController controller = Get.find<PatrolCheckInController>();
  int step = 1;
  final TextEditingController locationNameController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.fetchLocation();
  }

  @override
  void dispose() {
    locationNameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void nextStep() {
    setState(() {
      step++;
    });
  }

  void prevStep() {
    setState(() {
      if (step > 1) step--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        title: const Text('Add Manual Patrol',
            style: TextStyle(color: AppColors.whiteColor)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (step) {
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildPhotoStep();
      case 3:
        return _buildNotesStep();
      case 4:
        return _buildSubmitStep();
      default:
        return _buildLocationStep();
    }
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📍 Manual Patrol Location', style: AppTextStyles.heading),
        const SizedBox(height: 8),
        Text(
          'Please ensure you are at the correct location by matching GPS coordinates.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current GPS: [${controller.getCurrentGPSString()}'),
            ],
          )),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: locationNameController,
          decoration: const InputDecoration(
            labelText: 'Manual Location Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (locationNameController.text.trim().isEmpty) {
                 Get.snackbar(
                                    'Error',
                                    'Please enter a location name',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
               
                return;
              }
              nextStep();
            },
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
        Obx(() {
          final hasImage = controller.capturedImage.value != null;
          return Column(
            children: [
              hasImage
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(controller.capturedImage.value!, height: 180),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => controller.retakePhoto(),
                          child: const Text('Retake Photo'),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => controller.takePicture(context),
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.camera_alt, size: 64, color: AppColors.primary),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasImage ? nextStep : null,
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: 'Add patrol notes (optional)',
              hintStyle: AppTextStyles.hint,
              border: InputBorder.none,
            ),
            maxLines: 5,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: nextStep,
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: prevStep,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Back',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primary,
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
              Text('Location Name: ${locationNameController.text}'),
              Text('Current GPS: ${controller.getCurrentGPSString()}'),
              if (controller.capturedImage.value != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(controller.capturedImage.value!, height: 80),
                  ),
                ),
              if (noteController.text.isNotEmpty)
                Text('Notes: ${noteController.text}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    final latLng = controller.currentLatLng.value;
                    if (latLng == null) {
                        Get.snackbar(
                                    'Error',
                                    'Current location not available',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                     
                      return;
                    }
                    if (controller.capturedImage.value == null) {
                      
                        Get.snackbar(
                                    'Error',
                                    'Please take a selfie before submitting',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                
                      return;
                    }
                    controller.isLoading.value = true;
                    await controller.addManualPatrolApi(
                      manualLocationName: locationNameController.text.trim(),
                      manualLatitude: latLng.latitude,
                      manualLongitude: latLng.longitude,
                      selfie: controller.capturedImage.value!,
                      note: noteController.text.trim(),
                    );
                    controller.isLoading.value = false;
                    // Always navigate back after submit, even if overlays are not open
                    if (mounted) {

                      Navigator.of(context).pop();
                      controller.fetchPatrolLocationsFromAPI();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Submit Patrol Report',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.whiteColor,
                    ),
                  ),
          )),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              'Cancel',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.greyColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
