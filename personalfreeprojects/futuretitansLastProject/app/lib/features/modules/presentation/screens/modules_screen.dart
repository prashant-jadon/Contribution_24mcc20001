import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/module_provider.dart';
import '../../data/models/module_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesProvider);
    final user = ref.watch(authControllerProvider).user;
    final isPaid = user?.isPaid ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Modules'),
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: modulesAsync.when(
          data: (modules) {
             if (modules.isEmpty) {
               return const Center(child: Text('No modules available.'));
             }
             return RefreshIndicator(
               onRefresh: () => ref.refresh(modulesProvider.future),
               color: AppTheme.primaryGold,
               child: ListView.builder(
                 padding: const EdgeInsets.all(16),
                 itemCount: modules.length,
                 itemBuilder: (context, index) {
                   final module = modules[index];
                   return _buildModuleCard(context, module, isPaid);
                 },
               ),
             );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading modules: ${error.toString()}'),
                ElevatedButton(
                  onPressed: () => ref.refresh(modulesProvider),
                  child: const Text('Retry'),
                )
              ],
            )
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, ModuleModel module, bool isPaid) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: InkWell(
        onTap: () {
           if (isPaid) {
             context.push('/modules/${module.id}');
           } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Please complete payment to access modules.')),
             );
           }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Badge
            Stack(
              children: [
                if (module.coverImage != null && module.coverImage!.isNotEmpty)
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      image: DecorationImage(
                        image: NetworkImage(module.coverImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: AppTheme.primaryGold.withValues(alpha: 0.1),
                    child: const Center(
                      child: Icon(Icons.book_outlined, size: 48, color: AppTheme.primaryGold),
                    ),
                  ),
                
                // Difficulty Badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.9),
                       borderRadius: BorderRadius.circular(12),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.05),
                           blurRadius: 4,
                           offset: const Offset(0, 2),
                         )
                       ]
                     ),
                     child: Text(
                       module.difficulty.toUpperCase(),
                       style: TextStyle(
                         color: _getDifficultyColor(module.difficulty),
                         fontSize: 10,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 0.5,
                       ),
                     ),
                   ),
                ),

                // Lock Icon or Check Mark
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        )
                      ]
                    ),
                    child: !isPaid
                      ? const Icon(Icons.lock_outline, color: Colors.grey, size: 20)
                      : (module.isCompleted 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          : const Icon(Icons.play_arrow, color: AppTheme.primaryGold, size: 20)),
                  ),
                )
              ],
            ),
            
            // Text Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (module.mentorProfilePicture != null && module.mentorProfilePicture!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryGold, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(module.mentorProfilePicture!),
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Instructor',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    module.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    module.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${module.estimatedTime} mins', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const Spacer(),
                      // Progress indicator
                      SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${module.progress}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                               value: module.progress / 100,
                               backgroundColor: Colors.grey.shade200,
                               color: AppTheme.primaryGold,
                               minHeight: 4,
                               borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advance': case 'advanced': return Colors.red;
      default: return AppTheme.primaryGold;
    }
  }
}

