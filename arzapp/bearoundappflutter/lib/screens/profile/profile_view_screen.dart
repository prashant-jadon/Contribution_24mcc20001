import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../models/profile_model.dart';
import '../../models/message_model.dart';
import '../../providers/messages_provider.dart';
import '../../providers/auth_provider.dart';
import '../messages/message_request_screen.dart';

class ProfileViewScreen extends StatefulWidget {
  final ProfileModel profile;

  const ProfileViewScreen({super.key, required this.profile});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  late PageController _pageController;
  Timer? _autoSwipeTimer;
  int _currentPhotoIndex = 0;
  bool _isUserSwiping = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.profile.photos.length > 1) {
      _startAutoSwipe();
    }
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isUserSwiping && mounted) {
        if (_currentPhotoIndex < widget.profile.photos.length - 1) {
          _currentPhotoIndex++;
        } else {
          _currentPhotoIndex = 0; // Loop back to first photo
        }
        _pageController.animateToPage(
          _currentPhotoIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPhotoIndex = index;
    });
    // Restart auto-swipe timer after manual swipe
    if (widget.profile.photos.length > 1) {
      _autoSwipeTimer?.cancel();
      _isUserSwiping = true;
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _isUserSwiping = false;
          _startAutoSwipe();
        }
      });
    }
  }

  void _handleManualSwipe(int direction) {
    // Cancel auto-swipe when user manually swipes
    _autoSwipeTimer?.cancel();
    _isUserSwiping = true;
    
    if (direction > 0 && _currentPhotoIndex < widget.profile.photos.length - 1) {
      // Swipe left - next photo
      _currentPhotoIndex++;
      _pageController.animateToPage(
        _currentPhotoIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (direction < 0 && _currentPhotoIndex > 0) {
      // Swipe right - previous photo
      _currentPhotoIndex--;
      _pageController.animateToPage(
        _currentPhotoIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    
    // Resume auto-swipe after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isUserSwiping = false;
        _startAutoSwipe();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // App Bar with profile image
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile Image
                  if (widget.profile.photos.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.profile.photos.length,
                      itemBuilder: (context, index) {
                        // Use blurred image if available, otherwise use regular url
                        final photo = widget.profile.photos[index];
                        final imageUrl = photo.blurredUrl?.isNotEmpty == true
                            ? photo.blurredUrl!
                            : photo.url;
                        return Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.surfaceDark,
                            child: const Icon(
                              Icons.person,
                              size: 100,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: AppTheme.surfaceDark,
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.backgroundDark.withOpacity(0.8),
                          AppTheme.backgroundDark,
                        ],
                        stops: const [0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                  // Photo indicators
                  if (widget.profile.photos.length > 1)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.profile.photos.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: (MediaQuery.of(context).size.width - 40) /
                                widget.profile.photos.length -
                                4,
                            height: 3,
                            decoration: BoxDecoration(
                              color: index == _currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name/Username and Age
                  Consumer2<MessagesProvider, AuthProvider>(
                    builder: (context, messagesProvider, authProvider, _) {
                      // Check if there's an existing conversation with this user
                      final currentUserId = authProvider.user?.id;
                      final profileUserId = widget.profile.userId;
                      
                      // Find conversation with this user
                      ConversationModel? existingConversation;
                      bool isNotRevealed = false;
                      if (currentUserId != null && profileUserId != null) {
                        try {
                          existingConversation = messagesProvider.conversations.firstWhere(
                            (conv) => conv.otherUserId == profileUserId,
                          );
                          // If conversation exists and user is not revealed, show username
                          isNotRevealed = existingConversation != null && !existingConversation.isOtherUserRevealed;
                        } catch (e) {
                          // No conversation found
                          existingConversation = null;
                        }
                      }
                      
                      // If viewing from inbox and not revealed, show username instead of name
                      final displayName = (isNotRevealed || widget.profile.name.isEmpty)
                          ? (widget.profile.username ?? 'Anonymous')
                          : widget.profile.name;
                      
                      return Text(
                        '${displayName}${widget.profile.age != null ? ', ${widget.profile.age}' : ''}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ).animate().fadeIn().slideY(begin: 0.2);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Location & Details
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (widget.profile.location?.city != null)
                        _buildInfoChip(
                          Icons.location_on_outlined,
                          widget.profile.location!.city!,
                        ),
                      if (widget.profile.college?.name != null)
                        _buildInfoChip(
                          Icons.school_outlined,
                          widget.profile.college!.name!,
                        ),
                      if (widget.profile.workplace?.company != null)
                        _buildInfoChip(
                          Icons.work_outline,
                          widget.profile.workplace!.company!,
                        ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 24),

                  // Bio
                  if (widget.profile.bio != null && widget.profile.bio!.isNotEmpty) ...[
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.profile.bio!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Why on app
                  if (widget.profile.whyOnApp != null && widget.profile.whyOnApp!.isNotEmpty) ...[
                    _buildPromptCard(
                      'Why I\'m on this app',
                      widget.profile.whyOnApp!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Looking for
                  if (widget.profile.lookingFor != null && widget.profile.lookingFor!.isNotEmpty) ...[
                    _buildPromptCard(
                      'What I\'m looking for',
                      widget.profile.lookingFor!,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Interests
                  if (widget.profile.interests.isNotEmpty) ...[
                    Text(
                      'Interests',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.profile.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.textTertiary.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Relationship Intent
                  if (widget.profile.relationshipIntent != null) ...[
                    _buildPromptCard(
                      'Looking for',
                      widget.profile.relationshipIntent!,
                      icon: Icons.favorite_outline,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Match Score
                  if (widget.profile.matchScore != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.1),
                            AppTheme.accentPurple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Compatibility Score',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${widget.profile.matchScore}% match',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Consumer2<MessagesProvider, AuthProvider>(
        builder: (context, messagesProvider, authProvider, _) {
          // Check if there's an existing conversation with this user
          final currentUserId = authProvider.user?.id;
          final profileUserId = widget.profile.userId;
          
          // Find conversation with this user
          ConversationModel? existingConversation;
          if (currentUserId != null && profileUserId != null) {
            try {
              existingConversation = messagesProvider.conversations.firstWhere(
                (conv) => conv.otherUserId == profileUserId,
              );
            } catch (e) {
              // No conversation found
              existingConversation = null;
            }
          }

          // Hide button if conversation exists (regardless of reveal status)
          // If user is viewing from inbox, they already have a conversation
          final shouldHideButton = existingConversation != null &&
              existingConversation.id.isNotEmpty;

          if (shouldHideButton) {
            return const SizedBox.shrink(); // Hide the button
          }

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MessageRequestScreen(
                              profile: widget.profile,
                              source: 'profile_view',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Send Message Request'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard(String title, String answer, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

