
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/addLoacation/add_location_screen.dart';
import 'package:security_guard/modules/addLoacation/edit_location_screen.dart';
import 'package:security_guard/modules/addLoacation/location_controller.dart';

class LocationsListScreen extends StatelessWidget {
  const LocationsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LocationController controller = Get.put(LocationController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
        actions: [
          IconButton(
            onPressed: () => controller.refreshLocations(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Location Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => const AddLocationScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, color: AppColors.whiteColor),
              label: Text(
                'Add New Location',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.whiteColor,
                ),
              ),
            ),
          ),
          // Locations List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading locations...'),
                    ],
                  ),
                );
              }

              if (controller.locations.isEmpty) {
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
                        'No locations available',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.greyColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.refreshLocations(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.locations.length,
                itemBuilder: (context, index) {
                  final location = controller.locations[index];
                  return _buildLocationCard(location);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Location location) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Card(
        color: AppColors.whiteColor,
        elevation: 2,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: location.status ? AppColors.greenColor : AppColors.greyColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.whiteColor,
            ),
          ),
          title: Text(
            location.locationName,
            style: AppTextStyles.subtitle,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lat: ${location.latitude}, Lng: ${location.longitude}',
                style: AppTextStyles.hint,
              ),
              Text(
                'Radius: ${location.radius}m',
                style: AppTextStyles.hint,
              ),
            ],
          ),
          trailing: IconButton(
            onPressed: () {
              Get.to(() => EditLocationScreen(location: location));
            },
            icon: const Icon(Icons.edit, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}