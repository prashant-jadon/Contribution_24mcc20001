import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../providers/dashboard_provider.dart';
import '../../../modules/presentation/providers/module_provider.dart';
import '../../../modules/data/models/module_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final modulesAsync = ref.watch(modulesProvider);

    int completedModules = 0;
    int totalModules = 0;
    int overallProgress = 0;
    int totalTimeSpent = 0;

    if (user != null) {
      completedModules = user.modulesProgress.where((m) => m.completionPercentage >= 100).length;
      totalTimeSpent = user.modulesProgress.fold(0, (sum, m) => sum + m.timeSpent);
      if (user.modulesProgress.isNotEmpty) {
        overallProgress = (user.modulesProgress.fold(0, (sum, m) => sum + m.completionPercentage) / user.modulesProgress.length).round();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDD6), // Light warm background
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () {
               ref.read(authControllerProvider.notifier).logout();
               context.go('/login');
            },
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(authControllerProvider);
            ref.invalidate(modulesProvider);
            ref.invalidate(recentAchievementsProvider);
          },
          color: AppTheme.primaryGold,
          child: modulesAsync.when(
            data: (modules) {
              totalModules = modules.length;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user != null && !user.isPaid)
                      _buildPaymentBanner(context),
                      
                    _buildHeader(user, overallProgress),
                    const SizedBox(height: 24),
                    
                    _buildProfileCard(user),
                    const SizedBox(height: 16),
                    _buildQuickLinks(),
                    const SizedBox(height: 24),
                    
                    // Charts
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildProgressChart(user, modules)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTimeTracker(totalTimeSpent)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildCalendarAndRecent(user, modules),
                    const SizedBox(height: 24),
                    
                    _buildBadgesGrid(user, modules),
                    const SizedBox(height: 24),
                    
                    _buildSummaryStats(totalModules, completedModules),
                    const SizedBox(height: 16),
                    
                    _buildTotalJourney(overallProgress),
                    const SizedBox(height: 24),
                    
                    _buildModuleTasksDarkCard(user, modules, completedModules),
                    const SizedBox(height: 48),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  // ALL UI WIDGET METHODS BELOW
  
  Widget _buildPaymentBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔓 ', style: TextStyle(fontSize: 20)),
              Text(
                'Unlock Full Access',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryGoldDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your payment to access all modules and AI features.',
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.credit_card, size: 18),
              label: const Text('Pay ₹999', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel? user, int overallProgress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome in, ${user?.name.split(' ').first ?? 'Titan'}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w300,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Modules', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$overallProgress%', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * (overallProgress / 100),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Progress', style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildProfileCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
            backgroundImage: (user?.profilePicture != null && user!.profilePicture!.isNotEmpty)
                ? NetworkImage(user.profilePicture!)
                : null,
            child: (user?.profilePicture == null || user!.profilePicture!.isEmpty)
                ? const Icon(Icons.person, size: 40, color: AppTheme.primaryGold)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Innovation Student', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${user?.ssiScore ?? 0}', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Text('SSI Score', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildQuickLinkItem(Icons.settings, 'Profile Settings', () => context.push('/profile')),
          const Divider(height: 1, color: Colors.black12),
          _buildQuickLinkItem(Icons.book, 'Learning Modules', () => context.go('/modules')),
        ],
      ),
    );
  }

  Widget _buildQuickLinkItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
    );
  }

  Widget _buildProgressChart(UserModel? user, List<ModuleModel> allModules) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: allModules.take(4).toList().asMap().entries.map((entry) {
              int idx = entry.key;
              ModuleModel mod = entry.value;
              final modProgress = user?.modulesProgress.firstWhere((p) => p.moduleId == mod.id, orElse: () => ModuleProgress(moduleId: '', completedChapters: [], completionPercentage: 0, timeSpent: 0));
              final double val = (modProgress?.completionPercentage ?? 0) / 100.0;
              final color = val >= 1.0 ? AppTheme.primaryGold : (val > 0 ? AppTheme.primaryGoldLight : Colors.grey.shade300);
              
              return Column(
                children: [
                  Container(
                    width: 14,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 14,
                      height: 80 * val,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('M${idx+1}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTracker(int totalTimeSeconds) {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    final progress = (hours / 10).clamp(0.0, 1.0); // Assuming 10h goal
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Time Tracker', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progress),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value > 0 ? value : 0.05,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
                  const Text('WORK TIME', style: TextStyle(fontSize: 8, color: Colors.black54, letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarAndRecent(UserModel? user, List<ModuleModel> modules) {
    // Generate dates
    final now = DateTime.now();
    
    // Find recent activity
    final progressList = user?.modulesProgress ?? [];
    // Dart has no easy way to get the last accessed if we didn't save it. So we'll just show the first 2 modules in progress.
    final recent = progressList.where((p) => p.completionPercentage > 0 && p.completionPercentage < 100).take(2).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(now.month)} ${now.year}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final d = now.add(Duration(days: index - now.weekday + 1));
              final isToday = d.day == now.day && d.month == now.month;
              return Column(
                children: [
                  Text(['M','T','W','T','F','S','S'][d.weekday - 1], style: TextStyle(fontSize: 10, color: isToday ? Colors.black87 : Colors.black45, fontWeight: isToday ? FontWeight.bold : FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday ? AppTheme.primaryGold : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${d.day}', style: TextStyle(fontSize: 12, color: isToday ? Colors.white : Colors.black87, fontWeight: isToday ? FontWeight.bold : FontWeight.w400)),
                  )
                ],
              );
            }),
          ),
          const SizedBox(height: 24),
          if (recent.isNotEmpty)
            ...recent.map((mp) {
              final mod = modules.firstWhere((m) => m.id == mp.moduleId, orElse: () => ModuleModel(id: '', title: 'Module', description: '', difficulty: 'beginner', estimatedTime: 0, chapters: []));
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mod.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('${mp.completionPercentage}% complete · ${mp.completedChapters.length} done', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                    const Icon(Icons.play_circle_fill, color: AppTheme.primaryGold),
                  ],
                ),
              );
            })
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No recent activity. Start learning!', style: TextStyle(color: Colors.black54)),
            )
        ],
      ),
    );
  }

  String _getMonthName(int m) {
    return ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
  }

  Widget _buildBadgesGrid(UserModel? user, List<ModuleModel> modules) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Badges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text('Earned by completing modules', style: TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final mod = modules[index];
              final mp = user?.modulesProgress.firstWhere((p) => p.moduleId == mod.id, orElse: () => ModuleProgress(moduleId: '', completedChapters: [], completionPercentage: 0, timeSpent: 0));
              final isDone = (mp?.completionPercentage ?? 0) >= 100;
              final icons = [Icons.emoji_events, Icons.star, Icons.verified, Icons.shield];
              
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDone ? Colors.white : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDone ? AppTheme.primaryGold.withValues(alpha: 0.5) : Colors.transparent),
                  boxShadow: isDone ? [BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.2), blurRadius: 10)] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: isDone ? AppTheme.primaryGold : Colors.grey.shade200,
                      child: Icon(icons[index % icons.length], color: isDone ? Colors.white : Colors.grey, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mod.title,
                      style: TextStyle(fontSize: 9, fontWeight: isDone ? FontWeight.bold : FontWeight.normal, color: isDone ? Colors.black87 : Colors.black45),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(int totalModules, int completedModules) {
    return Row(
      children: [
        Expanded(child: _buildMiniStatCard(Icons.book, '$totalModules', 'Modules')),
        const SizedBox(width: 12),
        Expanded(child: _buildMiniStatCard(Icons.emoji_events, '$completedModules', 'Complete')),
        const SizedBox(width: 12),
        // Since Badges == Completed Modules for now
        Expanded(child: _buildMiniStatCard(Icons.verified, '$completedModules', 'Badges')),
      ],
    );
  }

  Widget _buildMiniStatCard(IconData icon, String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildTotalJourney(int overallProgress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Journey', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width * (overallProgress / 100),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text('$overallProgress%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }

  Widget _buildModuleTasksDarkCard(UserModel? user, List<ModuleModel> modules, int completedModules) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Module Tasks', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
              Text('$completedModules/${modules.length}', style: const TextStyle(color: AppTheme.primaryGold, fontSize: 24, fontWeight: FontWeight.w300)),
            ],
          ),
          const SizedBox(height: 24),
          ...modules.map((mod) {
            final mp = user?.modulesProgress.firstWhere((p) => p.moduleId == mod.id, orElse: () => ModuleProgress(moduleId: '', completedChapters: [], completionPercentage: 0, timeSpent: 0));
            final isDone = (mp?.completionPercentage ?? 0) >= 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(isDone ? Icons.check_circle : Icons.play_circle_outline, color: isDone ? AppTheme.primaryGold : Colors.white54, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mod.title,
                                  style: TextStyle(
                                    color: isDone ? Colors.white54 : Colors.white,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text('${mod.chapters.length} Chapters', style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          Icon(isDone ? Icons.check : Icons.circle_outlined, color: isDone ? AppTheme.primaryGold : Colors.white30, size: 20),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/modules'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('View All Modules', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
