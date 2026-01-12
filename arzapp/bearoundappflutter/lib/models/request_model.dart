import 'package:flutter/foundation.dart';
import 'profile_model.dart';

enum RequestStatus {
  pending,
  accepted,
  rejected,
  expired,
  cancelled,
}

class MessageRequestModel {
  final String id;
  final String senderId;
  final String? senderUsername;
  final ProfileModel? senderProfile;
  final String recipientId;
  final String? recipientUsername;
  final ProfileModel? recipientProfile;
  final String initialMessage;
  final RequestStatus status;
  final bool isAnonymous;
  final bool isPriority;
  final String source; // profile_link, search, discovery_feed, qr_code
  final int? expiresIn; // hours remaining
  final DateTime? expiresAt;
  final DateTime createdAt;

  MessageRequestModel({
    required this.id,
    required this.senderId,
    this.senderUsername,
    this.senderProfile,
    required this.recipientId,
    this.recipientUsername,
    this.recipientProfile,
    required this.initialMessage,
    this.status = RequestStatus.pending,
    this.isAnonymous = true,
    this.isPriority = false,
    this.source = 'discovery_feed',
    this.expiresIn,
    this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get statusDisplay {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.expired:
        return 'Expired';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory MessageRequestModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse sender profile if available
    ProfileModel? senderProfile;
    if (json['sender'] != null && json['sender'] is Map) {
      final sender = json['sender'] as Map<String, dynamic>;
      if (sender['profile'] != null && sender['profile'] is Map) {
        try {
          senderProfile = ProfileModel.fromJson(sender['profile'] as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing sender profile: $e');
        }
      }
    }

    // Parse recipient profile if available
    ProfileModel? recipientProfile;
    if (json['recipient'] != null && json['recipient'] is Map) {
      final recipient = json['recipient'] as Map<String, dynamic>;
      if (recipient['profile'] != null && recipient['profile'] is Map) {
        try {
          recipientProfile = ProfileModel.fromJson(recipient['profile'] as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error parsing recipient profile: $e');
        }
      }
    }

    // Parse status
    RequestStatus status = RequestStatus.pending;
    final statusStr = json['status']?.toString().toLowerCase() ?? 'pending';
    switch (statusStr) {
      case 'accepted':
        status = RequestStatus.accepted;
        break;
      case 'rejected':
        status = RequestStatus.rejected;
        break;
      case 'expired':
        status = RequestStatus.expired;
        break;
      case 'cancelled':
        status = RequestStatus.cancelled;
        break;
      default:
        status = RequestStatus.pending;
    }

    // Handle recipient ID - can be object (populated) or string
    String recipientId = '';
    String? recipientUsername;
    if (json['recipient'] != null) {
      if (json['recipient'] is Map) {
        recipientId = json['recipient']['_id']?.toString() ?? '';
        recipientUsername = json['recipient']['username'];
      } else {
        recipientId = json['recipient'].toString();
      }
    }

    // Handle sender ID - can be object (populated) or string
    String senderId = '';
    String? senderUsername;
    if (json['sender'] != null) {
      if (json['sender'] is Map) {
        senderId = json['sender']['_id']?.toString() ?? '';
        senderUsername = json['sender']['username'];
      } else {
        senderId = json['sender'].toString();
      }
    }

    return MessageRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: senderId,
      senderUsername: senderUsername,
      senderProfile: senderProfile,
      recipientId: recipientId,
      recipientUsername: recipientUsername,
      recipientProfile: recipientProfile,
      initialMessage: json['initialMessage'] ?? '',
      status: status,
      isAnonymous: json['isAnonymous'] ?? true,
      isPriority: json['isPriority'] ?? false,
      source: json['source'] ?? 'discovery_feed',
      expiresIn: json['expiresIn'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
    } catch (e, stackTrace) {
      debugPrint('Error parsing MessageRequestModel: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON: $json');
      rethrow;
    }
  }
}

class RequestStatsModel {
  final int pendingReceived;
  final int pendingSent;
  final int accepted;
  final int rejected;
  final int dailyRequestsUsed;
  final int dailyRequestsLimit;
  final int remainingRequests;

  RequestStatsModel({
    this.pendingReceived = 0,
    this.pendingSent = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.dailyRequestsUsed = 0,
    this.dailyRequestsLimit = 5,
    this.remainingRequests = 5,
  });

  factory RequestStatsModel.fromJson(Map<String, dynamic> json) {
    return RequestStatsModel(
      pendingReceived: json['pendingReceived'] ?? 0,
      pendingSent: json['pendingSent'] ?? 0,
      accepted: json['accepted'] ?? 0,
      rejected: json['rejected'] ?? 0,
      dailyRequestsUsed: json['dailyRequestsUsed'] ?? 0,
      dailyRequestsLimit: json['dailyRequestsLimit'] ?? 5,
      remainingRequests: json['remainingRequests'] ?? 5,
    );
  }
}

