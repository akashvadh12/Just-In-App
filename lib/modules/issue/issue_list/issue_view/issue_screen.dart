import 'package:flutter/material.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:security_guard/shared/widgets/issue_Resolve_card.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Issue> _issues;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadMockData();
  }

  void _loadMockData() {
    _issues = [
      Issue(
        id: '1',
        title: 'Broken Gate Lock',
        description: 'Main gate lock broken. Urgent fix needed.',
        location: 'East Gate',
        time: 'Today, 10:23 AM',
        status: IssueStatus.new_issue,
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZ7t5FgjtqkfaIklnozuric72i2RnzU6e9ww&s',
      ),
      Issue(
        id: '2',
        title: 'Broken Security Camera',
        description: 'Security camera not working properly. Needs replacement.',
        location: 'Building A - East Wing, Floor 3',
        time: 'Jan 23, 2024 - 14:30',
        status: IssueStatus.new_issue,
        imageUrl:
            'https://5.imimg.com/data5/SELLER/Default/2022/8/YZ/VH/FX/46273132/dome-cctv-camera.jpg',
      ),
      Issue(
        id: '3',
        title: 'Trash Cleared',
        description: 'Trash cleared. Clean area confirmed.',
        location: 'Main Entrance',
        time: 'Yesterday, 4:30 PM',
        status: IssueStatus.resolved,
        imageUrl:
            'https://www.checkatrade.com/blog/wp-content/uploads/2024/02/waste-clearance-near-me.jpg',
      ),
    ];
  }

  void _handleIssueUpdate(Issue updatedIssue) {
    setState(() {
      final index = _issues.indexWhere((issue) => issue.id == updatedIssue.id);
      if (index != -1) {
        _issues[index] = updatedIssue;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Issues', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIssuesList(IssueStatus.new_issue),
                _buildIssuesList(IssueStatus.resolved),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.whiteColor,
      child: TabBar(
        controller: _tabController,
        labelStyle: AppTextStyles.body,
        tabs: [
          Tab(text: 'New (${_getIssueCount(IssueStatus.new_issue)})'),
          Tab(text: 'Resolved (${_getIssueCount(IssueStatus.resolved)})'),
        ],
      ),
    );
  }

  Widget _buildIssuesList(IssueStatus status) {
    final filteredIssues =
        _issues.where((issue) => issue.status == status).toList();

    if (filteredIssues.isEmpty) {
      return Center(
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
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredIssues.length,
      itemBuilder: (context, index) {
        return IssueCard(
          issue: filteredIssues[index],
          onIssueUpdated: _handleIssueUpdate,
        );
      },
    );
  }

  int _getIssueCount(IssueStatus status) {
    return _issues.where((issue) => issue.status == status).length;
  }
}
