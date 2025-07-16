
// Updated Issue class to handle the new API response structure
class Issue {
  final String id;
  final String title;
  final String description;
  final String location;
  final String time;
  final IssueStatus status;
  final String imageUrl;
  final List<String> images;
  final List<String> issuePhotos;
  final List<String> resolvePhotos;
  final String? creatorName;
  final String? resolverName;
  final String? creatorPhoto;
  final String? resolverPhoto;
  final String? creatorGaurdId;
  final String? resolverGaurdId;
  final double? latitude;
  final double? longitude;
  final String? resolutionNote;
  final String? createdAt;
  final String? resolvedAt;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.time,
    required this.status,
    required this.imageUrl,
    this.images = const [],
    this.issuePhotos = const [],
    this.resolvePhotos = const [],
    this.creatorName,
    this.resolverName,
    this.creatorPhoto,
    this.resolverPhoto,
    this.creatorGaurdId,
    this.resolverGaurdId,
    this.latitude,
    this.longitude,
    this.resolutionNote,
    this.createdAt,
    this.resolvedAt,
  });

  factory Issue.fromApiJson(Map<String, dynamic> json) {
    // Handle issuePhotos
    List<String> issuePhotos = [];
    if (json['issuePhotos'] != null && json['issuePhotos'] is List) {
      issuePhotos = (json['issuePhotos'] as List).map((e) => e.toString()).toList();
    }
    
    // Handle resolvePhotos
    List<String> resolvePhotos = [];
    if (json['resolvePhotos'] != null && json['resolvePhotos'] is List) {
      resolvePhotos = (json['resolvePhotos'] as List).map((e) => e.toString()).toList();
    }
    
    // Fallback for images (legacy support)
    List<String> images = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        images = (json['images'] as List<dynamic>).map((e) => e.toString()).toList();
      } else if (json['images'] is String && json['images'].isNotEmpty) {
        images = [json['images']];
      }
    }
    
    // If no images, try imageUrl or image fields
    if (images.isEmpty) {
      if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
        images = [json['imageUrl'].toString()];
      } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
        images = [json['image'].toString()];
      }
    }
    
    // Prefer issuePhotos for main image, fallback to images
    final mainImage = issuePhotos.isNotEmpty
        ? issuePhotos.first
        : (images.isNotEmpty ? images.first : '');

    return Issue(
      id: json['issueId']?.toString() ?? json['id']?.toString() ?? '',
      title: _generateTitle(json['description']?.toString() ?? json['title']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      location: _generateLocation(json['latitude'], json['longitude']),
      time: _formatDateTime(json['createdAt']?.toString()),
      status: _parseApiStatus(json['status']?.toString()),
      imageUrl: mainImage,
      images: images,
      issuePhotos: issuePhotos,
      resolvePhotos: resolvePhotos,
      creatorName: json['creatorName']?.toString(),
      resolverName: json['resolverName']?.toString(),
      creatorPhoto: json['creatorPhoto']?.toString(),
      resolverPhoto: json['resolverPhoto']?.toString(),
      creatorGaurdId: json['creatorGaurdId']?.toString(),
      resolverGaurdId: json['resolverGaurdId']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      resolutionNote: json['resolutionNote']?.toString(),
      createdAt: _formatDateTime(json['createdAt']?.toString()),
      resolvedAt: _formatDateTime(json['resolvedAt']?.toString()),
    );
  }
   
   

  // CopyWith method for creating modified copies of Issue
  Issue copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? time,
    IssueStatus? status,
    String? imageUrl,
    List<String>? images,
    List<String>? issuePhotos,
    List<String>? resolvePhotos,
    String? creatorName,
    String? resolverName,
    String? creatorPhoto,
    String? resolverPhoto,
    String? creatorGaurdId,
    String? resolverGaurdId,
    double? latitude,
    double? longitude,
    String? resolutionNote,
    String? createdAt,
    String? resolvedAt,
  }) {
    return Issue(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      time: time ?? this.time,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      issuePhotos: issuePhotos ?? this.issuePhotos,
      resolvePhotos: resolvePhotos ?? this.resolvePhotos,
      creatorName: creatorName ?? this.creatorName,
      resolverName: resolverName ?? this.resolverName,
      creatorPhoto: creatorPhoto ?? this.creatorPhoto,
      resolverPhoto: resolverPhoto ?? this.resolverPhoto,
      creatorGaurdId: creatorGaurdId ?? this.creatorGaurdId,
      resolverGaurdId: resolverGaurdId ?? this.resolverGaurdId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }


  static String _generateTitle(String description) {
    if (description.isEmpty) return 'Issue';
    // Take first 30 characters or until first sentence
    final words = description.split(' ');
    if (words.length <= 5) return description;
    return '${words.take(5).join(' ')}...';
  }

  static String _generateLocation(dynamic lat, dynamic lng) {
    if (lat == null || lng == null) return 'Unknown location';
    return 'Lat: ${lat.toString()}, Lng: ${lng.toString()}';
  }

  static String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  static IssueStatus _parseApiStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'new':
        return IssueStatus.new_issue;
      case 'resolved':
        return IssueStatus.resolved;
      default:
        return IssueStatus.new_issue;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

enum IssueStatus {
  new_issue,
  resolved,
}