import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/issue/IssueResolution/issue_details_Screens/controller/issue_resolve_controller.dart';
import 'package:security_guard/modules/issue/issue_list/controller/issue_controller.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:security_guard/shared/widgets/Custom_Snackbar/Custom_Snackbar.dart';
import 'package:photo_view/photo_view.dart';

class IssueDetailScreen extends StatefulWidget {
  final Issue issue;
  final String userId;

  const IssueDetailScreen({
    super.key,
    required this.issue,
    required this.userId,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final TextEditingController _resolutionController = TextEditingController();
  late IssueDetailController controller;
  late Issue _currentIssue;

  final IssuesController issuesController = Get.find<IssuesController>();


  @override
  void initState() {
    super.initState();
    _currentIssue = widget.issue;
    // Set an initial value for the resolution notes.
    _resolutionController.text = widget.issue.resolutionNote ?? '';
    controller = Get.put(IssueDetailController());
    controller.initializeIssue(widget.issue, widget.userId);
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    Get.delete<IssueDetailController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Resolve Issue ',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: GetX<IssueDetailController>(
        builder: (controller) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIssueHeader(),
                _buildLocationMap(controller),
                _buildCurrentLocationDisplay(),
                _buildResolutionSection(),
                _buildPhotosSection(),
                controller.currentIssue.value?.status ==
                                  IssueStatus.resolved ?
                _buildResolvedPhotosSection() : SizedBox.shrink(),

                _buildUpdatedPhotosSection(),
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIssueHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${_currentIssue.id.toUpperCase()}-2024-0123',
                style: AppTextStyles.hint.copyWith(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              _buildStatusBadge(
                controller.currentIssue.value?.status ?? _currentIssue.status,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentIssue.title,
            style: AppTextStyles.heading.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reported: ${_currentIssue.time}',
            style: AppTextStyles.hint.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _currentIssue.location,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(IssueDetailController controller) {
    final issue = controller.currentIssue.value;
    final userPosition = controller.currentPosition.value;

    if (issue == null) return const SizedBox.shrink();

    final issueLatLng = LatLng(issue.latitude ?? 0.0, issue.longitude ?? 0.0);
    final userLatLng =
        userPosition != null
            ? LatLng(userPosition.latitude, userPosition.longitude)
            : null;

    final distance =
        userLatLng != null
            ? const Distance().as(LengthUnit.Meter, issueLatLng, userLatLng)
            : null;

    final isWithinRange = distance != null && distance <= 50;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(initialCenter: issueLatLng),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: issueLatLng,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                if (userLatLng != null)
                  Marker(
                    point: userLatLng,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.person_pin_circle,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
            if (distance != null)
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isWithinRange ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      isWithinRange
                          ? 'You are within 50 meters (${distance.toStringAsFixed(1)} m)'
                          : 'Too far! (${distance.toStringAsFixed(1)} m from target)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

void _showZoomableImage(BuildContext context, ImageProvider imageProvider) {
  final controller = PhotoViewController();
  final scaleStateController = PhotoViewScaleStateController();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: PhotoView(
                imageProvider: imageProvider,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                controller: controller,
                scaleStateController: scaleStateController,
              ),
            ),
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Zoom controls
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom in button
                  GestureDetector(
                    onTap: () {
                      final currentScale = controller.scale ?? 1.0;
                      controller.scale = (currentScale * 1.1).clamp(0.2, 2.0);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Zoom out button
                  GestureDetector(
                    onTap: () {
                      final currentScale = controller.scale ?? 1.0;
                      controller.scale = (currentScale / 1.5).clamp(0.2, 2.0);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.zoom_out,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Reset zoom button
                  GestureDetector(
                    onTap: () {
                      controller.scale = 1.0;
                      scaleStateController.scaleState = PhotoViewScaleState.initial;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.center_focus_strong,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildPhotosSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Original Photos',
            style: AppTextStyles.heading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _currentIssue.issuePhotos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showZoomableImage(
                    context,
                    NetworkImage(_currentIssue.issuePhotos[index]),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _currentIssue.issuePhotos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildResolvedPhotosSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resolved Photos',
            style: AppTextStyles.heading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _currentIssue.resolvePhotos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showZoomableImage(
                    context,
                    NetworkImage(_currentIssue.resolvePhotos[index]),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _currentIssue.resolvePhotos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatedPhotosSection() {
    return GetX<IssueDetailController>(
      builder: (controller) {
        if (controller.selectedImages.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Updated Photos',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showZoomableImage(
                            context,
                            FileImage(controller.selectedImages[index]),
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                controller.selectedImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => controller.removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentLocationDisplay() {
    return GetX<IssueDetailController>(
      builder: (controller) {
        if (controller.currentPosition.value == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Location',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${controller.currentPosition.value!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${controller.currentPosition.value!.longitude.toStringAsFixed(6)}',
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResolutionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resolution Details',
            style: AppTextStyles.heading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            enabled:(controller.currentIssue.value?.status ==
                                  IssueStatus.resolved) ? false : true ,
            controller: _resolutionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter resolution notes...',
              hintStyle: AppTextStyles.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return GetX<IssueDetailController>(
      builder: (controller) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Add Updated Photos Button
           (controller.currentIssue.value?.status ==
                                  IssueStatus.resolved) ? SizedBox.shrink() : SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => _showImagePickerOptions(context),
                  icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                  label: const Text(
                    'Add Updated Photos',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ) ,

              const SizedBox(height: 20),
              // Mark as Resolved Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (controller.currentIssue.value?.status ==
                              IssueStatus.resolved ||
                          controller.isLoading.value)
                      ? null
                      : () => _markAsResolved(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (controller.currentIssue.value?.status ==
                                IssueStatus.resolved ||
                            controller.isLoading.value)
                        ? Colors.grey
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          (controller.currentIssue.value?.status ==
                                  IssueStatus.resolved)
                              ? 'Already Resolved'
                              : 'Mark as Resolved',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(IssueStatus status) {
    String text;
    Color color;

    switch (status) {
      case IssueStatus.new_issue:
        text = 'New';
        color = AppColors.error;
        break;
      case IssueStatus.pending:
        text = 'Pending';
        color = Colors.orange;
        break;
      case IssueStatus.resolved:
        text = 'Resolved';
        color = AppColors.greenColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showImagePickerOptions(
    BuildContext context,
    // IncidentReportController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  _buildImageOption(
                    icon: Icons.photo_camera,
                    title: 'Camera',
                    subtitle: 'Take a new photo',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).pop();
                      // controller.pickImage();
                       controller.pickImages(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    subtitle: 'Choose from gallery',
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(context).pop();
                      // controller.pickMultipleImages();
                   controller.pickImages(ImageSource.gallery);

                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  
  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }


  void _markAsResolved() async {
    if (_resolutionController.text.trim().isEmpty) {
      CustomSnackbar.showError(
        'Required Field',
        'Please Enter Required Field Before Proceeding',
      );
      return;
    }

    if (controller.currentPosition.value == null) {
      CustomSnackbar.showError(
        'Location Error',
        'Please capture current location first',
      );
      return;
    }

    bool success = await controller.resolveIssue(
      _resolutionController.text.trim(),
    );

    if (success) {
      CustomSnackbar.showSuccess(
        'Issue Resolved',
        'Issue marked as resolved successfully!',
      );

      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          issuesController.refreshIssues();
          Navigator.pop(context, controller.currentIssue.value);
        }
      });
    } else {
      CustomSnackbar.showError(
        'Resolution Failed',
        controller.errorMessage.value.isNotEmpty
            ? controller.errorMessage.value
            : 'Failed to resolve issue. Please try again.',
      );
    }
  }
}