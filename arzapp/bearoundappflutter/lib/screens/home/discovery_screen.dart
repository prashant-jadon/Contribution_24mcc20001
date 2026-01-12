import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/profile/profile_card.dart';
import '../messages/message_request_screen.dart';
import '../notifications/notifications_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discoveryProvider = Provider.of<DiscoveryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      // Set default "show me" based on user's interestedIn
      discoveryProvider.setDefaultShowMeFromProfile(authProvider.profile);
      discoveryProvider.loadDiscoveryFeed();
      // Load notification count
      notificationProvider.loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextProfile() {
    final provider = Provider.of<DiscoveryProvider>(context, listen: false);
    if (_currentIndex < provider.profiles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Load more profiles
      provider.loadDiscoveryFeed();
    }
  }

  void _skipProfile() {
    final provider = Provider.of<DiscoveryProvider>(context, listen: false);
    if (provider.profiles.isNotEmpty && _currentIndex < provider.profiles.length) {
      provider.skipProfile(provider.profiles[_currentIndex].id);
      _nextProfile();
    }
  }

  void _sendMessage() {
    final provider = Provider.of<DiscoveryProvider>(context, listen: false);
    if (provider.profiles.isNotEmpty && _currentIndex < provider.profiles.length) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MessageRequestScreen(
            profile: provider.profiles[_currentIndex],
            source: 'discovery_feed',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'arz',
                style: TextStyle(
                  color: AppTheme.backgroundDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusError,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationProvider.unreadCount > 99
                              ? '99+'
                              : notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Consumer<DiscoveryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.profiles.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (provider.profiles.isEmpty) {
            return _buildEmptyState(provider);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDiscoveryFeed(),
            color: AppTheme.primary,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: provider.profiles.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return ProfileCard(
                  profile: provider.profiles[index],
                  onSkip: _skipProfile,
                  onMessage: _sendMessage,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(DiscoveryProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 60,
                color: AppTheme.textTertiary,
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text(
              'No profiles found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or check back later.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => provider.loadDiscoveryFeed(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const FilterBottomSheet();
      },
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _ageRange = const RangeValues(18, 40);
  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    final discoveryProvider = Provider.of<DiscoveryProvider>(context, listen: false);
    _selectedGender ??= discoveryProvider.gender;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Filters',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Age Range
          Text(
            'Age Range',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 60,
            divisions: 42,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.textTertiary.withOpacity(0.3),
            onChanged: (values) {
              setState(() {
                _ageRange = values;
              });
            },
          ),

          const SizedBox(height: 16),

          // Gender
          Text(
            'Show me',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: ['Women', 'Men', 'Everyone'].map((gender) {
              final isSelected = _selectedGender == gender;
              return ChoiceChip(
                label: Text(gender),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedGender = selected ? gender : null;
                  });
                },
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.backgroundDark : AppTheme.textPrimary,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Apply button
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Provider.of<DiscoveryProvider>(context, listen: false)
                        .clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<DiscoveryProvider>(context, listen: false)
                        .setFilters(
                      ageMin: _ageRange.start.round(),
                      ageMax: _ageRange.end.round(),
                      gender: _selectedGender?.toLowerCase(),
                    );
                    Provider.of<DiscoveryProvider>(context, listen: false)
                        .loadDiscoveryFeed();
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

