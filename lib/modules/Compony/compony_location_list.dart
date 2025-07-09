import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/Compony/Edit_location.dart';
import 'package:security_guard/modules/Compony/compony_location_controller.dart';
import 'package:security_guard/modules/addLoacation/add_location_screen.dart';
import 'package:security_guard/modules/addLoacation/edit_location_screen.dart';

class CompanyLocationsListScreen extends StatelessWidget {
  const CompanyLocationsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CompanyLocationController controller = Get.put(
      CompanyLocationController(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Locations'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.whiteColor,
        actions: [
          IconButton(
            onPressed: () => controller.refreshCompanyLocations(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Location Button
          // Container(
          //   width: double.infinity,
          //   margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          //   child: ElevatedButton.icon(
          //     onPressed: () {
          //       Get.to(() => const AddLocationScreen());
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppColors.primary,
          //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //     icon: const Icon(Icons.add, color: AppColors.whiteColor),
          //     label: Text(
          //       'Add New Company Location',
          //       style: AppTextStyles.subtitle.copyWith(
          //         color: AppColors.whiteColor,
          //       ),
          //     ),
          //   ),
          // ),
          // Company Locations List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading company locations...'),
                    ],
                  ),
                );
              }

              if (controller.companyLocations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: AppColors.greyColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No company locations available',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.greyColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.refreshCompanyLocations(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.companyLocations.length,
                itemBuilder: (context, index) {
                  final companyLocation = controller.companyLocations[index];
                  return _buildCompanyLocationCard(companyLocation);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLocationCard(CompanyLocation companyLocation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Card(
        color: AppColors.whiteColor,
        elevation: 2,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  companyLocation.status
                      ? AppColors.greenColor
                      : AppColors.greyColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.business, color: AppColors.whiteColor),
          ),
          title: Text(
            companyLocation.companyName,
            style: AppTextStyles.subtitle,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Industry: ${companyLocation.industry}',
                style: AppTextStyles.hint,
              ),
              Text(
                'Headquarters: ${companyLocation.headquarters}',
                style: AppTextStyles.hint,
              ),
              Text(
                'Location: ${companyLocation.locationName}',
                style: AppTextStyles.hint,
              ),
              // Text(
              //   'Coordinates: ${companyLocation.latitude}, ${companyLocation.longitude}',
              //   style: AppTextStyles.hint,
              // ),
              // Text(
              //   'Radius: ${companyLocation.radius}m',
              //   style: AppTextStyles.hint,
              // ),
              // Text(
              //   'Status: ${companyLocation.status ? 'Active' : 'Inactive'}',
              //   style: AppTextStyles.hint.copyWith(
              //     color: companyLocation.status ? AppColors.greenColor : AppColors.greyColor,
              //   ),
              // ),
            ],
          ),
          trailing: IconButton(
            onPressed: () {
              // Navigate to edit screen - you might need to adapt this based on your edit screen
              // Get.to(() => EditLocationScreen(location: companyLocation));
              Get.to(
                CompanyLocationEditScreen(
                  companyID: '${companyLocation.companyID}',
                ),
              );
            },
            icon: const Icon(Icons.edit, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
