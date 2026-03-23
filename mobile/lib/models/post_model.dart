import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String workerId;
  final String username;
  final String category;
  final String description;
  final String mediaUrl;
  final String mediaType;
  final List<dynamic> likedBy;
  final List<dynamic> savedBy;
  final List<dynamic> reportedBy;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.workerId,
    required this.username,
    required this.category,
    required this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.likedBy,
    required this.savedBy,
    required this.reportedBy,
    required this.commentCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'username': username,
      'category': category,
      'description': description,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'likedBy': likedBy,
      'savedBy': savedBy,
      'reportedBy': reportedBy,
      'commentCount': commentCount,
      'createdAt': createdAt,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      workerId: map['workerId'] ?? '',
      username: map['username'] ?? 'Unknown',
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      mediaType: map['mediaType'] ?? 'image',
      likedBy: map['likedBy'] ?? [],
      savedBy: map['savedBy'] ?? [],
      reportedBy: map['reportedBy'] ?? [],
      commentCount: map['commentCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
