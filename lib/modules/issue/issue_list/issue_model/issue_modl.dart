// Enhanced Issue Model
import 'package:flutter/material.dart';

enum IssueStatus { new_issue, pending, resolved }

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
  final double? latitude;
  final double? longitude;
  final String? resolutionNote;
  final DateTime? createdAt;
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
    this.latitude,
    this.longitude,
    this.resolutionNote,
    this.createdAt,
    this.resolvedAt,
  });

  factory Issue.fromApiJson(Map<String, dynamic> json) {
    // Handle new API fields for images
    List<String> issuePhotos = [];
    List<String> resolvePhotos = [];
    if (json['issuePhotos'] != null && json['issuePhotos'] is List) {
      issuePhotos = (json['issuePhotos'] as List).map((e) => e.toString()).toList();
    }
    if (json['resolvePhotos'] != null && json['resolvePhotos'] is List) {
      resolvePhotos = (json['resolvePhotos'] as List).map((e) => e.toString()).toList();
    }
    // Fallback for images (legacy)
    List<String> images = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        images = (json['images'] as List<dynamic>).map((e) => e.toString()).toList();
      } else if (json['images'] is String && json['images'].isNotEmpty) {
        images = [json['images']];
      }
    }
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
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      resolutionNote: json['resolutionNote']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      resolvedAt: _formatDateTime(json['resolvedAt']?.toString()),
    );
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String _generateTitle(String description) {
    if (description.isEmpty) return 'Issue Report';
    
    final words = description.trim().split(RegExp(r'\s+'));
    if (words.length <= 4) return description;
    
    return '${words.take(4).join(' ')}...';
  }

  static String _generateLocation(dynamic latitude, dynamic longitude) {
    final lat = _parseDouble(latitude);
    final lng = _parseDouble(longitude);
    
    if (lat == null || lng == null || lat == 0 || lng == 0) {
      return 'Location not specified';
    }
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  static String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'Unknown time';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday, ${_formatTime(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 
        ? dateTime.hour - 12 
        : dateTime.hour == 0 ? 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static IssueStatus _parseApiStatus(String? status) {
    if (status == null) return IssueStatus.new_issue;
    
    switch (status.toLowerCase().trim()) {
      case 'pending':
      case 'in_progress':
      case 'inprogress':
        return IssueStatus.pending;
      case 'resolved':
      case 'completed':
      case 'closed':
        return IssueStatus.resolved;
      case 'new':
      case 'open':
      case 'reported':
      default:
        return IssueStatus.new_issue;
    }
  }

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
    double? latitude,
    double? longitude,
    String? resolutionNote,
    DateTime? createdAt,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issueId': id,
      'title': title,
      'description': description,
      'location': location,
      'time': time,
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'images': images,
      'issuePhotos': issuePhotos,
      'resolvePhotos': resolvePhotos,
      'creatorName': creatorName,
      'resolverName': resolverName,
      'latitude': latitude,
      'longitude': longitude,
      'resolutionNote': resolutionNote,
      'createdAt': createdAt?.toIso8601String(),
      'resolvedAt': resolvedAt,
    };
  }

  @override
  String toString() {
    return 'Issue(id: $id, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Issue && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}