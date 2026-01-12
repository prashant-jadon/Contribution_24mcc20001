import 'package:flutter/foundation.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final NotificationData? data;
  final String? relatedUserId;
  final String? relatedUsername;
  final String? relatedUserPhoto;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.relatedUserId,
    this.relatedUsername,
    this.relatedUserPhoto,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Parse related user if available
    String? relatedUserId;
    String? relatedUsername;
    String? relatedUserPhoto;
    
    if (json['relatedUser'] != null) {
      if (json['relatedUser'] is Map) {
        final relatedUser = json['relatedUser'] as Map<String, dynamic>;
        relatedUserId = relatedUser['_id']?.toString();
        relatedUsername = relatedUser['username']?.toString();
        // Extract photo from profile
        final profile = relatedUser['profile'];
        if (profile != null && profile is Map) {
          final photos = profile['photos'];
          if (photos != null && photos is List && photos.isNotEmpty) {
            relatedUserPhoto = photos[0]['url'] ?? photos[0]['blurredUrl'];
          }
        }
      } else if (json['relatedUser'] is String) {
        relatedUserId = json['relatedUser'].toString();
      }
    }

    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? NotificationData.fromJson(json['data']) : null,
      relatedUserId: relatedUserId,
      relatedUsername: relatedUsername,
      relatedUserPhoto: relatedUserPhoto,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data?.toJson(),
      'relatedUserId': relatedUserId,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class NotificationData {
  final String? targetType;
  final String? targetId;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  NotificationData({
    this.targetType,
    this.targetId,
    this.actionUrl,
    this.metadata,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      targetType: json['targetType'],
      targetId: json['targetId']?.toString(),
      actionUrl: json['actionUrl'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (targetType != null) 'targetType': targetType,
      if (targetId != null) 'targetId': targetId,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

