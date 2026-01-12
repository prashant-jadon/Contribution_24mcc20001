import 'package:flutter/foundation.dart';

class ReactionModel {
  final String userId;
  final String emoji;

  ReactionModel({required this.userId, required this.emoji});

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      userId: json['user'] ?? '',
      emoji: json['emoji'] ?? '',
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderUsername;
  final String content;
  final String type; // text, image, system
  final bool isRead;
  final DateTime? readAt;
  final String? replyTo;
  final List<ReactionModel> reactions;
  final bool isDeleted;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderUsername,
    required this.content,
    this.type = 'text',
    this.isRead = false,
    this.readAt,
    this.replyTo,
    this.reactions = const [],
    this.isDeleted = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    List<ReactionModel> reactions = [];
    if (json['reactions'] != null) {
      reactions = (json['reactions'] as List)
          .map((r) => ReactionModel.fromJson(r))
          .toList();
    }

    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversation'] ?? '',
      senderId: json['sender']?['_id'] ?? json['sender'] ?? '',
      senderUsername: json['sender']?['username'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      replyTo: json['replyTo'],
      reactions: reactions,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class ConversationModel {
  final String id;
  final String otherUserId;
  final String otherUsername;
  final String? otherUserName;
  final String? otherUserPhoto;
  final bool isOtherUserRevealed;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final String? lastMessageType;
  final int unreadCount;
  final bool isAnonymous;
  final bool isMuted;
  final bool myRevealStatus;
  final String? initiatorId;
  final String? revealRequestedBy;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    this.otherUserName,
    this.otherUserPhoto,
    this.isOtherUserRevealed = false,
    this.lastMessageContent,
    this.lastMessageAt,
    this.lastMessageType,
    this.unreadCount = 0,
    this.isAnonymous = true,
    this.isMuted = false,
    this.myRevealStatus = false,
    this.initiatorId,
    this.revealRequestedBy,
    required this.createdAt,
  });
  
  bool get isInitiator {
    // This will be set by comparing with current user ID in the provider
    return false; // Will be overridden
  }

  String get displayName {
    if (isOtherUserRevealed && otherUserName != null) {
      return otherUserName!;
    }
    // Use username instead of "???" for anonymous users
    return otherUsername.isNotEmpty ? otherUsername : 'Anonymous';
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    try {
      final otherUser = json['otherUser'];
      final lastMessage = json['lastMessage'];

      // Handle otherUser ID - can be string or object
      String otherUserId = '';
      String otherUsername = '';
      String? otherUserName;
      bool isOtherUserRevealed = false;
      
      if (otherUser != null) {
        if (otherUser is Map) {
          otherUserId = otherUser['_id']?.toString() ?? '';
          otherUsername = otherUser['username']?.toString() ?? '';
          otherUserName = otherUser['profile']?['name']?.toString();
          isOtherUserRevealed = otherUser['isRevealed'] ?? false;
        } else if (otherUser is String) {
          otherUserId = otherUser;
        }
      }

      // Handle lastMessage
      String? lastMessageContent;
      DateTime? lastMessageAt;
      String? lastMessageType;
      
      if (lastMessage != null && lastMessage is Map) {
        lastMessageContent = lastMessage['content']?.toString();
        if (lastMessage['sentAt'] != null) {
          final sentAtStr = lastMessage['sentAt'].toString();
          lastMessageAt = DateTime.tryParse(sentAtStr);
        }
        lastMessageType = lastMessage['type']?.toString();
      }

      return ConversationModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        otherUserId: otherUserId,
        otherUsername: otherUsername,
        otherUserName: otherUserName,
        otherUserPhoto: _extractPhotoUrl(
          otherUser is Map<String, dynamic> 
              ? otherUser 
              : (otherUser is Map 
                  ? Map<String, dynamic>.from(otherUser) 
                  : null),
        ),
        isOtherUserRevealed: isOtherUserRevealed,
        lastMessageContent: lastMessageContent,
        lastMessageAt: lastMessageAt,
        lastMessageType: lastMessageType,
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        isAnonymous: json['isAnonymous'] ?? true,
        isMuted: json['isMuted'] ?? false,
        myRevealStatus: json['myRevealStatus'] ?? false,
        initiatorId: json['initiator']?.toString(),
        revealRequestedBy: json['revealRequestedBy']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing ConversationModel: $e');
      debugPrint('JSON: $json');
      rethrow;
    }
  }

  static String? _extractPhotoUrl(Map<String, dynamic>? otherUser) {
    if (otherUser == null) return null;
    
    final photos = otherUser['profile']?['photos'];
    if (photos == null || photos.isEmpty) return null;
    
    final isRevealed = otherUser['isRevealed'] ?? false;
    // If not revealed, use blurredUrl, otherwise use url
    if (!isRevealed) {
      return photos[0]['blurredUrl'] ?? photos[0]['url'];
    }
    
    return photos[0]['url'] ?? photos[0]['blurredUrl'];
  }
}

