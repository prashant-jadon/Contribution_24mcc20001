import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/api_service.dart';
import '../../providers/messages_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message_model.dart';
import '../../models/profile_model.dart';
import '../profile/profile_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _joinConversation();
  }

  void _loadMessages() {
    Provider.of<MessagesProvider>(context, listen: false)
        .loadMessages(widget.conversation.id);
  }

  void _joinConversation() {
    Provider.of<MessagesProvider>(context, listen: false)
        .joinConversation(widget.conversation.id);
  }

  @override
  void dispose() {
    Provider.of<MessagesProvider>(context, listen: false)
        .leaveConversation(widget.conversation.id);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isComposing = false;
    });

    final provider = Provider.of<MessagesProvider>(context, listen: false);
    await provider.sendMessage(widget.conversation.id, message);
  }

  void _showRevealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Reveal Your Identity'),
        content: const Text(
          'Are you sure you want to reveal your identity to this person? '
          'They will be able to see your name and photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<MessagesProvider>(context, listen: false);
              final success =
                  await provider.revealIdentity(widget.conversation.id);
              if (mounted) {
                if (success) {
                  // The provider will reload conversations and notify listeners
                  // The UI will update automatically via Consumer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Identity revealed successfully!'),
                      backgroundColor: AppTheme.statusSuccess,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reveal identity'),
                      backgroundColor: AppTheme.statusError,
                    ),
                  );
                }
              }
            },
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
  }

  void _showRequestRevealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Request to See Identity'),
        content: const Text(
          'Send a request to see this person\'s identity? '
          'They will receive a notification that you want to see them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<MessagesProvider>(context, listen: false);
              final success =
                  await provider.requestReveal(widget.conversation.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request sent! They will be notified.'),
                      backgroundColor: AppTheme.statusSuccess,
                    ),
                  );
                } else {
                  // Get error message from provider if available
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to send request. You may have already requested or identity is already revealed.'),
                      backgroundColor: AppTheme.statusError,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewProfile(BuildContext context, ConversationModel conversation) async {
    // Allow viewing profile even when not revealed (will show blurred images)

    // Check if we have username or user ID
    if (conversation.otherUsername.isEmpty && conversation.otherUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load profile: User information not available'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final apiService = ApiService();
      Response? response;

      // Try to fetch by username first, fallback to user ID
      if (conversation.otherUsername.isNotEmpty) {
        debugPrint('Fetching profile by username: ${conversation.otherUsername}');
        try {
          response = await apiService.getProfileByUsername(conversation.otherUsername);
        } catch (e) {
          debugPrint('Failed to fetch by username, trying user ID: $e');
          // If username lookup fails, try user ID as fallback
          if (conversation.otherUserId.isNotEmpty) {
            debugPrint('Fetching profile by user ID: ${conversation.otherUserId}');
            response = await apiService.getProfileByUserId(conversation.otherUserId);
          } else {
            rethrow;
          }
        }
      } else if (conversation.otherUserId.isNotEmpty) {
        // If no username, try user ID
        debugPrint('Fetching profile by user ID: ${conversation.otherUserId}');
        response = await apiService.getProfileByUserId(conversation.otherUserId);
      } else {
        // If neither username nor user ID available
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load profile: User information not available'),
              backgroundColor: AppTheme.statusError,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (response.statusCode == 200 && response.data['success']) {
          final data = response.data['data'];
          // The backend returns { profile: {...}, username: ..., ... }
          // So we need to extract the profile from the data object
          final profileData = data['profile'];
          
          if (profileData == null) {
            debugPrint('Profile data is null in response: ${response.data}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile data not found in response'),
                backgroundColor: AppTheme.statusError,
              ),
            );
            return;
          }
          
          debugPrint('Profile data received: $profileData');
          final profile = ProfileModel.fromJson(profileData);

          // Navigate to profile view
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileViewScreen(profile: profile),
            ),
          );
        } else {
          // Show error with more details
          final errorMessage = response.data['message'] ?? 'Failed to load profile';
          debugPrint('Profile fetch error: $errorMessage (Status: ${response.statusCode})');
          debugPrint('Username used: ${conversation.otherUsername}');
          debugPrint('User ID: ${conversation.otherUserId}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.statusError,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      debugPrint('Username: ${conversation.otherUsername}');
      debugPrint('User ID: ${conversation.otherUserId}');
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: AppTheme.statusError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id;

    return Consumer<MessagesProvider>(
      builder: (context, messagesProvider, _) {
        // Get the latest conversation from provider, fallback to widget.conversation
        final conversation = messagesProvider.conversations
                .firstWhere(
                  (c) => c.id == widget.conversation.id,
                  orElse: () => widget.conversation,
                );
        
        // Check if current user is the initiator (sender)
        final isInitiator = conversation.initiatorId != null &&
            conversation.initiatorId == currentUserId;

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppTheme.backgroundDarkGray,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            title: GestureDetector(
              onTap: () => _viewProfile(context, conversation),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.surfaceDark,
                    backgroundImage: conversation.otherUserPhoto != null
                        ? NetworkImage(conversation.otherUserPhoto!)
                        : null,
                    child: conversation.otherUserPhoto == null
                        ? Text(
                            conversation.isAnonymous ||
                                    !conversation.isOtherUserRevealed
                                ? (conversation.otherUsername.isNotEmpty 
                                    ? conversation.otherUsername[0].toUpperCase()
                                    : '?')
                                : Helpers.getInitials(conversation.displayName),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: conversation.isOtherUserRevealed
                                ? AppTheme.primary
                                : null,
                            decoration: conversation.isOtherUserRevealed
                                ? TextDecoration.underline
                                : null,
                          ),
                        ),
                        if (conversation.isAnonymous)
                          const Text(
                            'Anonymous chat',
                            style: TextStyle(
                              color: AppTheme.accentPurple,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Only show reveal button if user is initiator (sender) and not yet revealed
              if (isInitiator &&
                  conversation.isAnonymous &&
                  !conversation.myRevealStatus)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: AppTheme.accentPurple,
                      size: 20,
                    ),
                  ),
                  onPressed: _showRevealDialog,
                  tooltip: 'Reveal Identity',
                ),
              // Show request reveal button if user is receiver and other is not revealed
              // Allow multiple requests, so no need to check if already requested
              if (!isInitiator &&
                  conversation.isAnonymous &&
                  !conversation.isOtherUserRevealed)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.visibility_outlined,
                      color: AppTheme.accentGold,
                      size: 20,
                    ),
                  ),
                  onPressed: _showRequestRevealDialog,
                  tooltip: 'Request to See Identity',
                ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              // Handle menu actions
              if (value == 'block') {
                // Block user
              } else if (value == 'report') {
                // Report user
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: AppTheme.statusError),
                    SizedBox(width: 12),
                    Text('Block'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: AppTheme.statusWarning),
                    SizedBox(width: 12),
                    Text('Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<MessagesProvider>(
              builder: (context, provider, _) {
                final messages = provider.getMessages(conversation.id);

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 40,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Start the conversation!',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final showAvatar = !isMe &&
                        (index == messages.length - 1 ||
                            messages[index + 1].senderId != message.senderId);

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      showAvatar: showAvatar,
                      otherUserPhoto: conversation.otherUserPhoto, // Always pass photo (blurred if not revealed)
                      isAnonymous: conversation.isAnonymous,
                      isOtherUserRevealed: conversation.isOtherUserRevealed,
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDarkGray,
              border: Border(
                top: BorderSide(
                  color: AppTheme.textTertiary.withOpacity(0.1),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (text) {
                                setState(() {
                                  _isComposing = text.isNotEmpty;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _isComposing ? _sendMessage : null,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isComposing
                              ? AppTheme.primary
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.send,
                          color: _isComposing
                              ? AppTheme.backgroundDark
                              : AppTheme.textTertiary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final String? otherUserPhoto;
  final bool isAnonymous;
  final bool isOtherUserRevealed;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    this.otherUserPhoto,
    this.isAnonymous = false,
    this.isOtherUserRevealed = false,
  });

  @override
  Widget build(BuildContext context) {
    // Handle system messages
    if (message.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: AppTheme.accentGold,
                ),
                const SizedBox(width: 8),
                Text(
                  message.content,
                  style: TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.surfaceDark,
              backgroundImage: otherUserPhoto != null
                  ? NetworkImage(otherUserPhoto!)
                  : null,
              child: otherUserPhoto == null
                  ? const Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.textTertiary,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 36),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primary : AppTheme.surfaceDark,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? AppTheme.backgroundDark : AppTheme.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Helpers.formatChatTime(message.createdAt),
                      style: TextStyle(
                        color: isMe
                            ? AppTheme.backgroundDark.withOpacity(0.7)
                            : AppTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? AppTheme.backgroundDark.withOpacity(0.9)
                            : AppTheme.backgroundDark.withOpacity(0.6),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

