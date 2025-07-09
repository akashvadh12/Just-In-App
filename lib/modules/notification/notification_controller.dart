// notifications_controller.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Issue {
  final String issueId;
  final String description;
  final String status;
  final DateTime createdAt;
  final double latitude;
  final double longitude;
  final String? resolutionNote;
  final List<String> issuePhotos;
  final List<String> resolvePhotos;
  // bool isRead;

  Issue({
    required this.issueId,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    this.resolutionNote,
    required this.issuePhotos,
    required this.resolvePhotos,
    // this.isRead = false,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      issueId: json['issueId'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      resolutionNote: json['resolutionNote'],
      issuePhotos: List<String>.from(json['issuePhotos'] ?? []),
      resolvePhotos: List<String>.from(json['resolvePhotos'] ?? []),
      // isRead: false,
    );
  }
}

class NotificationsController extends ChangeNotifier {
  List<Issue> _issues = [];
  List<Issue> _filteredIssues = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'All';

  List<Issue> get issues => _filteredIssues;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  
  
  int get alertsCount => _issues.where((issue) => issue.status == 'new').length;
  int get remindersCount => _issues.where((issue) => issue.status == 'in_progress').length;

  void setFilter(String filter) {
    _selectedFilter = filter;
    _filterIssues();
    notifyListeners();
  }

  void _filterIssues() {
    switch (_selectedFilter) {
      case 'Alerts':
        _filteredIssues = _issues.where((issue) => issue.status == 'new').toList();
        break;
      case 'Reminders':
        _filteredIssues = _issues.where((issue) => issue.status == 'in_progress').toList();
        break;
      default:
        _filteredIssues = List.from(_issues);
    }
  }

  Future<void> fetchIssues() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://official.solarvision-cairo.com/top-list'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> issuesData = jsonDecode(response.body);
        _issues = issuesData.map((data) => Issue.fromJson(data)).toList();
        _issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _filterIssues();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to load notifications';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

 

  void markAsRead(String issueId) {
    final issue = _issues.firstWhere((issue) => issue.issueId == issueId);
    // issue.isRead = true;
    notifyListeners();
  }

  String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData getIssueIcon(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Icons.warning_amber_rounded;
      case 'in_progress':
        return Icons.access_time_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color getIssueColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color getIssueBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.red[50]!;
      case 'in_progress':
        return Colors.orange[50]!;
      case 'resolved':
        return Colors.green[50]!;
      default:
        return Colors.blue[50]!;
    }
  }

  bool isRecentIssue(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return difference.inHours < 24;
  }
}