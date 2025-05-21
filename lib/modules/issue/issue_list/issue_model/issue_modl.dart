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
}

enum IssueStatus {
  new_issue,
  pending,
  resolved
}