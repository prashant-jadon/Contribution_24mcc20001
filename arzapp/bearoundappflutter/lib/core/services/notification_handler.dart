import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/notification_provider.dart';
import '../../screens/messages/messages_screen.dart';
import '../../screens/messages/request_detail_screen.dart';
import '../../screens/messages/chat_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../core/services/api_service.dart';
import '../../models/profile_model.dart';
import '../../screens/profile/profile_view_screen.dart';

class NotificationHandler {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  void setupNotificationHandlers() {
    // Handle notification clicks
    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationTap(event.notification);
    });
  }

  Future<void> _handleNotificationTap(OSNotification notification) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator not available for notification tap');
      return;
    }

    final context = navigator.context;
    if (context == null) {
      debugPrint('Context not available for notification tap');
      return;
    }

    final additionalData = notification.additionalData;
    if (additionalData == null) {
      // If no data, just navigate to notifications screen
      _navigateToNotifications(navigator);
      return;
    }

    final type = additionalData['type'] as String?;
    final targetId = additionalData['targetId'] as String?;
    final targetType = additionalData['targetType'] as String?;

    debugPrint('Handling notification tap: type=$type, targetId=$targetId, targetType=$targetType');

    // Mark notification as read in app
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.loadUnreadCount();

    switch (type) {
      case 'message_request':
        if (targetId != null) {
          await _navigateToMessageRequest(navigator, context, targetId);
        } else {
          _navigateToMessages(navigator);
        }
        break;

      case 'request_accepted':
        if (targetId != null && targetType == 'conversation') {
          await _navigateToConversation(navigator, context, targetId);
        } else {
          _navigateToMessages(navigator);
        }
        break;

      case 'new_message':
        if (targetId != null && targetType == 'conversation') {
          await _navigateToConversation(navigator, context, targetId);
        } else {
          _navigateToMessages(navigator);
        }
        break;

      case 'identity_reveal':
      case 'reveal_requested':
        if (targetId != null && targetType == 'conversation') {
          await _navigateToConversation(navigator, context, targetId);
        } else {
          _navigateToMessages(navigator);
        }
        break;

      case 'profile_view':
        if (targetId != null) {
          await _navigateToProfile(navigator, targetId);
        } else {
          _navigateToNotifications(navigator);
        }
        break;

      default:
        _navigateToNotifications(navigator);
        break;
    }
  }

  void _navigateToMessages(NavigatorState navigator) {
    // Navigate to messages tab in main navigation
    // This will be handled by the app's navigation structure
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const MessagesScreen(),
      ),
    );
  }

  void _navigateToNotifications(NavigatorState navigator) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  Future<void> _navigateToMessageRequest(
    NavigatorState navigator,
    BuildContext context,
    String requestId,
  ) async {
    try {
      final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
      await messagesProvider.loadPendingRequests();
      await messagesProvider.loadSentRequests();

      final request = messagesProvider.pendingRequests.firstWhere(
        (r) => r.id == requestId,
        orElse: () => messagesProvider.sentRequests.firstWhere(
          (r) => r.id == requestId,
          orElse: () => throw Exception('Request not found'),
        ),
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) => RequestDetailScreen(
            request: request,
            isPending: messagesProvider.pendingRequests.contains(request),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to message request: $e');
      _navigateToMessages(navigator);
    }
  }

  Future<void> _navigateToConversation(
    NavigatorState navigator,
    BuildContext context,
    String conversationId,
  ) async {
    try {
      final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
      await messagesProvider.loadConversations();

      final conversation = messagesProvider.conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to conversation: $e');
      _navigateToMessages(navigator);
    }
  }

  Future<void> _navigateToProfile(
    NavigatorState navigator,
    String userId,
  ) async {
    try {
      final apiService = ApiService();
      final response = await apiService.getProfileByUserId(userId);

      if (response.statusCode == 200 && response.data['success']) {
        final profileData = response.data['data']['profile'];
        final profile = ProfileModel.fromJson(profileData);

        navigator.push(
          MaterialPageRoute(
            builder: (_) => ProfileViewScreen(profile: profile),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to profile: $e');
      _navigateToNotifications(navigator);
    }
  }
}

