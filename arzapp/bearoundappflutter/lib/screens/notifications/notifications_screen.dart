import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/notification_provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';
import '../messages/request_detail_screen.dart';
import '../messages/chat_screen.dart';
import '../profile/profile_view_screen.dart';
import '../../core/services/api_service.dart';
import '../../models/profile_model.dart';
import '../../models/request_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.loadNotifications(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        provider.loadNotifications();
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read if not already read
    if (!notification.isRead) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.markAsRead(notification.id);
    }

    // Navigate based on notification type
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case 'message_request':
        if (data.targetId != null) {
          // Navigate to request detail
          final messagesProvider =
              Provider.of<MessagesProvider>(context, listen: false);
          await messagesProvider.loadPendingRequests();
          
          final request = messagesProvider.pendingRequests.firstWhere(
            (r) => r.id == data.targetId,
            orElse: () => messagesProvider.sentRequests.firstWhere(
              (r) => r.id == data.targetId,
              orElse: () => throw Exception('Request not found'),
            ),
          );

          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RequestDetailScreen(
                  request: request,
                  isPending: request.status == RequestStatus.pending &&
                      messagesProvider.pendingRequests.contains(request),
                ),
              ),
            );
          }
        }
        break;

      case 'request_accepted':
      case 'new_message':
        if (data.targetId != null && data.targetType == 'conversation') {
          // Navigate to conversation
          final messagesProvider =
              Provider.of<MessagesProvider>(context, listen: false);
          await messagesProvider.loadConversations();

          final conversation = messagesProvider.conversations.firstWhere(
            (c) => c.id == data.targetId,
            orElse: () => throw Exception('Conversation not found'),
          );

          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: conversation),
              ),
            );
          }
        }
        break;

      case 'profile_view':
        if (notification.relatedUserId != null) {
          // Navigate to profile
          try {
            final apiService = ApiService();
            final response = await apiService.getProfileByUserId(
              notification.relatedUserId!,
            );

            if (response.statusCode == 200 && response.data['success']) {
              final profileData = response.data['data']['profile'];
              final profile = ProfileModel.fromJson(profileData);

              if (mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileViewScreen(profile: profile),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error loading profile: $e');
          }
        }
        break;

      default:
        // For other types, just mark as read
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () async {
                  final success = await provider.markAllAsRead();
                  if (mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        backgroundColor: AppTheme.statusSuccess,
                      ),
                    );
                  }
                },
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadNotifications(refresh: true);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final notification = provider.notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDelete: () async {
                    final success = await provider.deleteNotification(notification.id);
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification deleted'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'message_request':
        return Icons.chat_bubble_outline;
      case 'request_accepted':
        return Icons.check_circle_outline;
      case 'request_rejected':
        return Icons.cancel_outlined;
      case 'new_message':
        return Icons.message_outlined;
      case 'identity_reveal':
        return Icons.visibility;
      case 'reveal_requested':
        return Icons.visibility_outlined;
      case 'profile_view':
        return Icons.person_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'message_request':
        return AppTheme.primary;
      case 'request_accepted':
        return AppTheme.statusSuccess;
      case 'request_rejected':
        return AppTheme.statusError;
      case 'new_message':
        return AppTheme.accentPurple;
      case 'identity_reveal':
        return AppTheme.accentGold;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.statusError,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppTheme.surfaceDark
                : AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: notification.isRead
                ? null
                : Border.all(
                    color: AppTheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar/Icon
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getIconColor().withOpacity(0.2),
                    backgroundImage: notification.relatedUserPhoto != null
                        ? NetworkImage(notification.relatedUserPhoto!)
                        : null,
                    child: notification.relatedUserPhoto == null
                        ? Icon(
                            _getIcon(),
                            color: _getIconColor(),
                            size: 24,
                          )
                        : null,
                  ),
                  if (!notification.isRead)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.backgroundDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Helpers.formatRelativeTime(notification.createdAt),
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

