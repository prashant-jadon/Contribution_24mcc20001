import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../models/profile_model.dart';

class ProfileCard extends StatefulWidget {
  final ProfileModel profile;
  final VoidCallback onSkip;
  final VoidCallback onMessage;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onSkip,
    required this.onMessage,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _currentPhotoIndex = 0;

  void _nextPhoto() {
    if (_currentPhotoIndex < widget.profile.photos.length - 1) {
      setState(() {
        _currentPhotoIndex++;
      });
    }
  }

  void _previousPhoto() {
    if (_currentPhotoIndex > 0) {
      setState(() {
        _currentPhotoIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            if (widget.profile.photos.isNotEmpty && 
                _currentPhotoIndex < widget.profile.photos.length &&
                widget.profile.photos[_currentPhotoIndex].url.isNotEmpty)
              GestureDetector(
                onTapUp: (details) {
                  final width = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < width / 3) {
                    _previousPhoto();
                  } else if (details.globalPosition.dx > width * 2 / 3) {
                    _nextPhoto();
                  }
                },
                child: Image.network(
                  widget.profile.photos[_currentPhotoIndex].url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading image: ${widget.profile.photos[_currentPhotoIndex].url}');
                    debugPrint('Error: $error');
                    return _buildPlaceholder();
                  },
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppTheme.surfaceDark,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              _buildPlaceholder(),

            // Photo indicators
            if (widget.profile.photos.length > 1)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(
                    widget.profile.photos.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index == _currentPhotoIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      AppTheme.backgroundDark.withOpacity(0.7),
                      AppTheme.backgroundDark.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Age
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.profile.name}${widget.profile.age != null ? ', ${widget.profile.age}' : ''}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 8),

                    // Location/College/Work
                    if (widget.profile.college?.name != null ||
                        widget.profile.workplace?.company != null ||
                        widget.profile.location?.city != null)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
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
                          if (widget.profile.location?.city != null)
                            _buildInfoChip(
                              Icons.location_on_outlined,
                              widget.profile.location!.city!,
                            ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                    const SizedBox(height: 12),

                    // Bio snippet
                    if (widget.profile.bio != null &&
                        widget.profile.bio!.isNotEmpty)
                      Text(
                        widget.profile.bio!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    // Interests
                    if (widget.profile.interests.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.profile.interests.take(4).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              interest,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Skip button
                        _ActionButton(
                          icon: Icons.close,
                          color: AppTheme.statusError,
                          onTap: widget.onSkip,
                          size: 64,
                        ),
                        const SizedBox(width: 32),
                        // Message button
                        _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          color: AppTheme.primary,
                          onTap: widget.onMessage,
                          size: 72,
                          isPrimary: true,
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceDark,
      child: const Center(
        child: Icon(
          Icons.person,
          size: 100,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 64,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(
            color: color,
            width: isPrimary ? 0 : 2,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? AppTheme.backgroundDark : color,
          size: size * 0.45,
        ),
      ),
    );
  }
}

