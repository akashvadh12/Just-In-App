// Issues Screen (unchanged)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/issue/issue_list/controller/issue_controller.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:security_guard/modules/issue/IssueResolution/issue_details_Screens/issue_Resolve_card.dart';
import 'package:security_guard/modules/issue/report_issue/report_incident_screen.dart';

class IssuesScreen extends StatelessWidget {
  final int initialTabIndex;
  const IssuesScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    final IssuesController controller = Get.put(IssuesController());

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text('Issues', style: TextStyle(color: Colors.white)),
          ),
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.search, color: Colors.white),
            //   onPressed: () {
            //     // Implement search functionality
            //   },
            // ),
            // IconButton(
            //   icon: const Icon(Icons.refresh, color: Colors.white),
            //   onPressed: () => controller.refreshIssues(),
            // ),
          ],
        ),
        body: Column(
          children: [
            _buildTabBar(controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return _buildErrorWidget(controller);
                }

                return TabBarView(
                  children: [
                    _buildIssuesList(controller, IssueStatus.new_issue),
                    _buildIssuesList(controller, IssueStatus.resolved),
                  ],
                );
              }),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to issue creation screen
            Get.to(IncidentReportScreen());

          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
      )),
    );
  }

  Widget _buildTabBar(IssuesController controller) {
    return Container(
      color: AppColors.whiteColor,
      child: Obx(
        () => TabBar(
          labelStyle: AppTextStyles.body,
          tabs: [
            Tab(text: 'New (${controller.newIssuesCount})'),
            Tab(text: 'Resolved (${controller.resolvedIssuesCount})'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(IssuesController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.errorMessage.value,
              style: AppTextStyles.body.copyWith(
                color: Colors.red[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.refreshIssues(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesList(IssuesController controller, IssueStatus status) {
    return Obx(() {
      final filteredIssues = controller.getIssuesByStatus(status);

      if (filteredIssues.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => controller.refreshIssues(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              
              height: Get.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      status == IssueStatus.new_issue
                          ? Icons.check_circle_outline
                          : Icons.history,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      status == IssueStatus.new_issue
                          ? 'No new issues'
                          : 'No resolved issues',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshIssues(),
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filteredIssues.length,
          itemBuilder: (context, index) {
            return IssueCard(
              issue: filteredIssues[index],
              onIssueUpdated:
                  (updatedIssue) => controller.updateIssue(updatedIssue),
            );
          },
        ),
      );
    });
  }
}

