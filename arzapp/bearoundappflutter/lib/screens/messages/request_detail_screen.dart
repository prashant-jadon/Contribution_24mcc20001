import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/messages_provider.dart';
import '../../models/request_model.dart';

class RequestDetailScreen extends StatefulWidget {
  final MessageRequestModel request;
  final bool isPending;

  const RequestDetailScreen({
    super.key,
    required this.request,
    required this.isPending,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late PageController _pageController;
  Timer? _autoSwipeTimer;
  int _currentPhotoIndex = 0;
  bool _isUserSwiping = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.isPending 
        ? widget.request.senderProfile 
        : widget.request.recipientProfile;
    final photos = profile?.photos ?? [];
    _pageController = PageController();
    if (photos.length > 1) {
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
    final profile = widget.isPending 
        ? widget.request.senderProfile 
        : widget.request.recipientProfile;
    final photos = profile?.photos ?? [];
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isUserSwiping && mounted) {
        if (_currentPhotoIndex < photos.length - 1) {
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
    final profile = widget.isPending 
        ? widget.request.senderProfile 
        : widget.request.recipientProfile;
    final photos = profile?.photos ?? [];
    if (photos.length > 1) {
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

  @override
  Widget build(BuildContext context) {
    final profile = widget.isPending 
        ? widget.request.senderProfile 
        : widget.request.recipientProfile;
    final name = profile?.name ?? (widget.isPending ? 'Anonymous' : 'User');
    final photos = profile?.photos ?? [];
    final isAnonymous = widget.request.isAnonymous;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // App Bar with profile images
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
                  // Profile Images
                  if (photos.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const BouncingScrollPhysics(),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        // For anonymous requests, use blurredUrl if available, otherwise use url
                        // Backend should set both url and blurredUrl to blurred version for anonymous requests
                        final photo = photos[index];
                        String imageUrl;
                        if (isAnonymous) {
                          // For anonymous requests, prefer blurredUrl, fallback to url
                          imageUrl = photo.blurredUrl?.isNotEmpty == true 
                              ? photo.blurredUrl! 
                              : photo.url;
                        } else {
                          // For non-anonymous requests, use regular url
                          imageUrl = photo.url;
                        }
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
                  if (photos.length > 1)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          photos.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: (MediaQuery.of(context).size.width - 40) /
                                photos.length -
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
                  // Name
                  Text(
                    widget.request.isAnonymous 
                        ? (widget.request.senderUsername?.isNotEmpty ?? false
                            ? widget.request.senderUsername!
                            : 'Anonymous')
                        : name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn().slideY(begin: 0.2),

                  if (widget.request.isAnonymous) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.visibility_off,
                            size: 16,
                            color: AppTheme.accentPurple,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Anonymous',
                            style: TextStyle(
                              color: AppTheme.accentPurple,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Source
                  Text(
                    'via ${_getSourceLabel(widget.request.source)}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  if (widget.request.expiresIn != null && widget.isPending) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.request.expiresIn! < 24
                            ? AppTheme.statusWarning.withOpacity(0.1)
                            : AppTheme.backgroundDarkGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: widget.request.expiresIn! < 24
                                ? AppTheme.statusWarning
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Expires in ${Helpers.formatExpiry(widget.request.expiresIn!)}',
                            style: TextStyle(
                              color: widget.request.expiresIn! < 24
                                  ? AppTheme.statusWarning
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.format_quote,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Their message',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.request.initialMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Helpers.formatRelativeTime(widget.request.createdAt),
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  if (!widget.isPending && widget.request.status != RequestStatus.pending) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusBackgroundColor(widget.request.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(widget.request.status),
                            color: _getStatusColor(widget.request.status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusMessage(widget.request.status),
                            style: TextStyle(
                              color: _getStatusColor(widget.request.status),
                              fontWeight: FontWeight.w600,
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
      bottomSheet: widget.isPending
          ? Container(
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
                      child: OutlinedButton(
                        onPressed: () => _handleReject(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.statusError,
                          side: const BorderSide(color: AppTheme.statusError),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAccept(context),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _handleAccept(BuildContext context) async {
    final provider = Provider.of<MessagesProvider>(context, listen: false);
    final success = await provider.acceptRequest(widget.request.id);

    if (context.mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted! You can now chat.'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept request'),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    }
  }

  void _handleReject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Reject Request?'),
        content: const Text(
          'Are you sure you want to reject this message request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusError,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = Provider.of<MessagesProvider>(context, listen: false);
      final success = await provider.rejectRequest(widget.request.id);

      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject request'),
              backgroundColor: AppTheme.statusError,
            ),
          );
        }
      }
    }
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'profile_link':
        return 'Profile Link';
      case 'search':
        return 'Search';
      case 'discovery_feed':
        return 'Discovery';
      case 'qr_code':
        return 'QR Code';
      default:
        return source;
    }
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return AppTheme.statusSuccess;
      case RequestStatus.rejected:
        return AppTheme.statusError;
      case RequestStatus.expired:
        return AppTheme.textTertiary;
      case RequestStatus.cancelled:
        return AppTheme.textTertiary;
      default:
        return AppTheme.statusWarning;
    }
  }

  Color _getStatusBackgroundColor(RequestStatus status) {
    return _getStatusColor(status).withOpacity(0.1);
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return Icons.check_circle_outline;
      case RequestStatus.rejected:
        return Icons.cancel_outlined;
      case RequestStatus.expired:
        return Icons.timer_off_outlined;
      case RequestStatus.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.pending_outlined;
    }
  }

  String _getStatusMessage(RequestStatus status) {
    switch (status) {
      case RequestStatus.accepted:
        return 'Request was accepted';
      case RequestStatus.rejected:
        return 'Request was rejected';
      case RequestStatus.expired:
        return 'Request has expired';
      case RequestStatus.cancelled:
        return 'Request was cancelled';
      default:
        return 'Request is pending';
    }
  }
}

