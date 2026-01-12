import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/messages_provider.dart';
import '../../models/message_model.dart';
import '../../models/request_model.dart';
import 'chat_screen.dart';
import 'request_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    final provider = Provider.of<MessagesProvider>(context, listen: false);
    provider.loadConversations();
    provider.loadPendingRequests();
    provider.loadSentRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Messages'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer<MessagesProvider>(
            builder: (context, provider, _) {
              return TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Inbox'),
                        if (provider.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              provider.unreadCount.toString(),
                              style: const TextStyle(
                                color: AppTheme.backgroundDark,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Requests'),
                        if (provider.pendingRequests.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.statusError,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              provider.pendingRequests.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Sent'),
                ],
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InboxTab(),
          _RequestsTab(),
          _SentTab(),
        ],
      ),
    );
  }
}

class _InboxTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingConversations && provider.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (provider.conversations.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.loadConversations(),
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _buildEmptyState(
                  context,
                  Icons.chat_bubble_outline,
                  'No conversations yet',
                  'Start a conversation by sending a message request',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadConversations(),
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.conversations.length,
            itemBuilder: (context, index) {
              return _ConversationTile(
                conversation: provider.conversations[index],
              ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
            },
          ),
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingRequests && provider.pendingRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (provider.pendingRequests.isEmpty) {
          return _buildEmptyState(
            context,
            Icons.inbox_outlined,
            'No pending requests',
            'When someone sends you a message request, it will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPendingRequests(),
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.pendingRequests.length,
            itemBuilder: (context, index) {
              return _RequestTile(
                request: provider.pendingRequests[index],
                isPending: true,
              ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
            },
          ),
        );
      },
    );
  }
}

class _SentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, provider, _) {
        // Show loading indicator if loading and empty
        if (provider.isLoadingRequests && provider.sentRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (provider.sentRequests.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.loadSentRequests(),
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _buildEmptyState(
                  context,
                  Icons.send_outlined,
                  'No sent requests',
                  'Requests you send will appear here',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadSentRequests(),
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.sentRequests.length,
            itemBuilder: (context, index) {
              final request = provider.sentRequests[index];
              return _RequestTile(
                request: request,
                isPending: false,
              ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
            },
          ),
        );
      },
    );
  }
}

Widget _buildEmptyState(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, size: 48, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: conversation.unreadCount > 0
            ? AppTheme.primary.withOpacity(0.05)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: conversation),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.backgroundDarkGray,
              backgroundImage: conversation.otherUserPhoto != null
                  ? NetworkImage(conversation.otherUserPhoto!)
                  : null,
              child: conversation.otherUserPhoto == null
                  ? Text(
                      conversation.isAnonymous || !conversation.isOtherUserRevealed
                          ? (conversation.otherUsername.isNotEmpty 
                              ? conversation.otherUsername[0].toUpperCase()
                              : '?')
                          : Helpers.getInitials(conversation.displayName),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            if (conversation.isAnonymous || !conversation.isOtherUserRevealed)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.visibility_off,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.displayName,
                style: TextStyle(
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              conversation.lastMessageAt != null
                  ? Helpers.formatRelativeTime(conversation.lastMessageAt!)
                  : '',
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? AppTheme.primary
                    : AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessageContent ?? 'Start chatting!',
                style: TextStyle(
                  color: conversation.unreadCount > 0
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: AppTheme.backgroundDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final MessageRequestModel request;
  final bool isPending;

  const _RequestTile({required this.request, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final profile = isPending ? request.senderProfile : request.recipientProfile;
    final name = profile?.name ?? 
                 (isPending 
                     ? (request.isAnonymous 
                         ? (request.senderUsername?.isNotEmpty ?? false
                             ? request.senderUsername!
                             : 'Anonymous')
                         : 'User') 
                     : 'User');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(
                request: request,
                isPending: isPending,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.backgroundDarkGray,
              backgroundImage: profile?.mainPhotoUrl.isNotEmpty == true
                  ? NetworkImage(profile!.mainPhotoUrl)
                  : null,
              child: profile?.mainPhotoUrl.isEmpty ?? true
                  ? const Icon(
                      Icons.person,
                      color: AppTheme.textSecondary,
                      size: 28,
                    )
                  : null,
            ),
            if (request.isAnonymous)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.visibility_off,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                request.isAnonymous 
                    ? (request.senderUsername?.isNotEmpty ?? false
                        ? request.senderUsername!
                        : 'Anonymous')
                    : name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (request.expiresIn != null && isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: request.expiresIn! < 24
                      ? AppTheme.statusWarning.withOpacity(0.2)
                      : AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  Helpers.formatExpiry(request.expiresIn!),
                  style: TextStyle(
                    color: request.expiresIn! < 24
                        ? AppTheme.statusWarning
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (!isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.statusDisplay,
                  style: TextStyle(
                    color: _getStatusColor(request.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          request.initialMessage,
          style: const TextStyle(color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isPending
            ? const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textTertiary,
              )
            : null,
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return AppTheme.statusWarning;
      case RequestStatus.accepted:
        return AppTheme.statusSuccess;
      case RequestStatus.rejected:
        return AppTheme.statusError;
      case RequestStatus.expired:
        return AppTheme.textTertiary;
      case RequestStatus.cancelled:
        return AppTheme.textTertiary;
    }
  }
}

