import 'package:flutter/material.dart';
import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:security_guard/shared/widgets/issue_card.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
        title: 'Unauthorized Vehicle',
        description: 'Unknown car parked for over 2 hours.',
        location: 'Basement Parking',
        time: 'Today, 09:15 AM',
        status: IssueStatus.pending,
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSTOXICu8ncKz5Tt6JFfD1u_vC8kofoSBK5Pw&s',
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                _buildIssuesList(IssueStatus.pending),
                _buildIssuesList(IssueStatus.resolved),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.whiteColor,
      child: TabBar(
        controller: _tabController,
        labelStyle:
            AppTextStyles
                .body, // Replace 'body' with an existing TextStyle from AppTextStyles
        tabs: [
          Tab(text: 'New (${_getIssueCount(IssueStatus.new_issue)})'),
          Tab(text: 'Pending (${_getIssueCount(IssueStatus.pending)})'),
          Tab(text: 'Resolved (${_getIssueCount(IssueStatus.resolved)})'),
        ],
      ),
    );
  }

  Widget _buildIssuesList(IssueStatus status) {
    final filteredIssues =
        _issues.where((issue) => issue.status == status).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredIssues.length,
      itemBuilder: (context, index) {
        return IssueCard(issue: filteredIssues[index]);
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2, // Issues tab
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.view_list), label: 'Patrol'),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_problem),
          label: 'Issues',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: "Attendance",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  int _getIssueCount(IssueStatus status) {
    return _issues.where((issue) => issue.status == status).length;
  }
}
