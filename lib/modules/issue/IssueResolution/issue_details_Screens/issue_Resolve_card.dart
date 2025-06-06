import 'package:flutter/material.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/issue/IssueResolution/issue_details_Screens/issuDetails.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences utility
class SharedPrefHelper {
  static Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('user_id');
    String? storedissueId = prefs.getString('issue_id');

    // Fallback to user_data key
    if (storedUserId == null || storedUserId.isEmpty) {
      storedUserId = prefs.getString('user_data_user_id');
      if (storedUserId != null && storedUserId.isNotEmpty) {
        await prefs.setString('user_id', storedUserId); // Cache it
      }
    }

    return storedUserId;
  }

  static Future<void> saveIssueId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('issue_id', id);
  }

  static Future<String?> getIssueId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('issue_id');
  }
}

class IssueCard extends StatelessWidget {
  final Issue issue;
  final Function(Issue)? onIssueUpdated;

  const IssueCard({super.key, required this.issue, this.onIssueUpdated});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final userId = await SharedPrefHelper.getStoredUserId();
          await SharedPrefHelper.saveIssueId(issue.id); // Save issue ID

          print('User ID retrieved: $userId');
          print('Issue ID saved: ${issue.id}');

          final updatedIssue = await Navigator.push<Issue>(
            context,
            MaterialPageRoute(
              builder: (context) => IssueDetailScreen(
                issue: issue,
                userId: userId ?? '',
              ),
            ),
          );

          if (updatedIssue != null && onIssueUpdated != null) {
            onIssueUpdated!(updatedIssue);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    issue.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.lightGrey,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: AppColors.greyColor,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.lightGrey,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.title,
                            style: AppTextStyles.heading.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(issue.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.description,
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.greyColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                issue.location,
                                style: AppTextStyles.hint,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.greyColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              issue.time,
                              style: AppTextStyles.hint,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
}
