enum IssueStatus { new_issue, pending, resolved }

class Issue {
  final String id;
  final String title;
  final String description;
  final String location;
  final String time;
  final IssueStatus status;
  final String imageUrl;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.time,
    required this.status,
    required this.imageUrl,
  });

  /// Factory constructor to create Issue from JSON
  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      time: json['time'] ?? '',
      status: _parseStatus(json['status']),
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  /// Helper method to parse IssueStatus from a string
  static IssueStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return IssueStatus.pending;
      case 'resolved':
        return IssueStatus.resolved;
      case 'new':
      case 'new_issue':
      default:
        return IssueStatus.new_issue;
    }
  }
}
