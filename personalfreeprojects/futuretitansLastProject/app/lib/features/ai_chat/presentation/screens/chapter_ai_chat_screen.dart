import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../../data/models/chat_model.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../widgets/zunnova_avatar.dart';

class ChapterAiChatScreen extends ConsumerStatefulWidget {
  final String moduleId;
  final String chapterId;

  const ChapterAiChatScreen({
    super.key,
    required this.moduleId,
    required this.chapterId,
  });

  @override
  ConsumerState<ChapterAiChatScreen> createState() => _ChapterAiChatScreenState();
}

class _ChapterAiChatScreenState extends ConsumerState<ChapterAiChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).init(widget.moduleId, widget.chapterId);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatControllerProvider.notifier).sendMessage(text);
      _msgController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    // Auto-scroll on new messages
    ref.listen(chatControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: Row(
          children: [
            zunnovaAvatar(
              size: 36,
              isTalking: chatState.isLoading,
            ),
            const SizedBox(width: 12),
            const Text('zunnova', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Finish Chapter Button
          if (widget.moduleId != 'global' && !chatState.isCompleted && chatState.messages.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final success = await ref.read(chatControllerProvider.notifier).finishChapter();
                if (success && context.mounted) {
                   final updatedState = ref.read(chatControllerProvider);
                   _showCompletionDialog(context, updatedState.ssiScore, isModuleCompleted: updatedState.isModuleCompleted);
                }
              },
              icon: const Icon(Icons.check_circle_outline, color: AppTheme.primaryGoldDark),
              label: const Text('Finish', style: TextStyle(color: AppTheme.primaryGoldDark)),
            ),
             if (chatState.isCompleted)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Messages Area
            Expanded(
              child: chatState.isLoading && chatState.messages.isEmpty
                  ? const Center(
                      child: zunnovaAvatar(
                        size: 150,
                        isTalking: true,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatState.messages.length + (chatState.isLoading && chatState.messages.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == chatState.messages.length) {
                          // Typing indicator
                          return _buildTypingIndicator();
                        }
                        final message = chatState.messages[index];
                        return _buildChatBubble(message);
                      },
                    ),
            ),

            // SSI Score Mini-Tracker (Optional mapping)
            if (chatState.ssiScore != null)
               Container(
                 padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                 color: Colors.black.withValues(alpha: 0.05),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('SSI Progress:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                     Text('S: ${chatState.ssiScore!['selfAwareness'] ?? 0} | U: ${chatState.ssiScore!['understandingOpportunities'] ?? 0} | R: ${chatState.ssiScore!['resilience'] ?? 0} | G: ${chatState.ssiScore!['growthExecution'] ?? 0} | E: ${chatState.ssiScore!['entrepreneurialLeadership'] ?? 0}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryGoldDark, fontWeight: FontWeight.w600),
                     )
                   ],
                 ),
               ),

            // Input Area
            if (!chatState.isCompleted)
              Container(
                padding: const EdgeInsets.all(16).copyWith(top: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                             const SizedBox(width: 16),
                             Expanded(
                               child: TextField(
                                 controller: _msgController,
                                 maxLines: 4,
                                 minLines: 1,
                                 textInputAction: TextInputAction.send,
                                 onSubmitted: (_) => _sendMessage(),
                                 decoration: const InputDecoration(
                                   hintText: 'Ask zunnova...',
                                   border: InputBorder.none,
                                   enabledBorder: InputBorder.none,
                                   focusedBorder: InputBorder.none,
                                   isDense: true,
                                   contentPadding: EdgeInsets.symmetric(vertical: 12),
                                 ),
                               ),
                             ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: chatState.isLoading ? null : _sendMessage,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: chatState.isLoading 
                            ? const SpinKitThreeBounce(color: Colors.white, size: 16.0)
                            : const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessageModel message) {
    final isAssistant = message.role == 'assistant';
    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAssistant ? AppTheme.surfaceWhite : AppTheme.darkBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAssistant ? 0 : 20),
            bottomRight: Radius.circular(isAssistant ? 20 : 0),
          ),
          border: isAssistant ? Border.all(color: Colors.black.withValues(alpha: 0.05)) : null,
          boxShadow: [
             if (isAssistant)
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: isAssistant ? AppTheme.textDark : Colors.white,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: const zunnovaAvatar(
          size: 32,
          isTalking: true,
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, Map<String, dynamic>? score, {bool isModuleCompleted = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(isModuleCompleted ? Icons.emoji_events : Icons.star, color: AppTheme.primaryGold, size: 64),
            const SizedBox(height: 24),
            Text(
              isModuleCompleted ? 'Module Completed!' : 'Chapter Completed!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isModuleCompleted
                 ? 'You have successfully finished all chapters for this module. You can now submit your idea!'
                 : 'Your SSI score has been updated based on your interaction. Keep up the great work!',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isModuleCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    context.pop(); // Close dialog
                    context.pop(); // Pop chat screen
                    context.pop(); // Pop player screen
                    context.push('/submit-idea');
                  },
                  child: const Text('Submit Your Idea', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    context.pop();
                    context.pop();
                    context.pop();
                  },
                  child: const Text('Maybe Later'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop(); // Close dialog
                    context.pop(); // Pop chat screen
                    context.pop(); // Pop player screen, back to module detail
                  },
                  child: const Text('Back to Course'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
