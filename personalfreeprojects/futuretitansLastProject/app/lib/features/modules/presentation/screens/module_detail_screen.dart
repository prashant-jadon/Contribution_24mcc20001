import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/module_model.dart';
import '../providers/module_provider.dart';

class ModuleDetailScreen extends ConsumerWidget {
  final String moduleId;

  const ModuleDetailScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is a bit of a hack for now, assuming the modules are already loaded in the list
    // A better approach would be to fetch the single module details if deep linking
    final modulesAsync = ref.watch(modulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Details'),
      ),
      body: modulesAsync.when(
        data: (modules) {
          try {
            final module = modules.firstWhere((m) => m.id == moduleId);
            return _buildModuleContent(context, module);
          } catch (e) {
            return const Center(child: Text('Module not found'));
          }
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildModuleContent(BuildContext context, ModuleModel module) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: module.coverImage == null || module.coverImage!.isEmpty
                  ? const LinearGradient(
                      colors: [AppTheme.primaryGold, AppTheme.primaryGoldDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              image: module.coverImage != null && module.coverImage!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(module.coverImage!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.darken),
                    )
                  : null,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    module.difficulty.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (module.mentorProfilePicture != null && module.mentorProfilePicture!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(module.mentorProfilePicture!),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 8),
                         Text(
                          'Instructor',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Text(
                  module.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${module.estimatedTime} mins',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'About this module',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            module.description,
             style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Chapters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${module.chapters.length} total',
                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Chapters List
          ...module.chapters.asMap().entries.map((entry) {
            final index = entry.key;
            final chapter = entry.value;
            // Hacky progress check: if module progress > (index/total)*100, it's complete/unlocked
            final isUnlocked = index == 0 || (module.progress / 100) >= (index / module.chapters.length);
            final isCompleted = (module.progress / 100) > ((index + 1) / module.chapters.length) || module.isCompleted;

             return _buildChapterListItem(context, module.id, chapter, index + 1, isUnlocked, isCompleted);
          }),
        ],
      ),
    );
  }

  Widget _buildChapterListItem(BuildContext context, String moduleId, ChapterModel chapter, int index, bool isUnlocked, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isUnlocked ? 2 : 0,
      color: isUnlocked ? AppTheme.surfaceWhite : Colors.grey.shade100,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted 
                ? Colors.green.withValues(alpha: 0.1) 
                : isUnlocked 
                    ? AppTheme.primaryGold.withValues(alpha: 0.1) 
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted 
                ? const Icon(Icons.check, color: Colors.green)
                : !isUnlocked
                    ? const Icon(Icons.lock_outline, color: Colors.grey)
                    : Text(
                        '$index',
                        style: const TextStyle(
                          color: AppTheme.primaryGoldDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
          ),
        ),
        title: Text(
          chapter.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? AppTheme.textDark : Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
             children: [
                Icon(_getIconForType(chapter.type), size: 14, color: isUnlocked ? AppTheme.textSecondary : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_capitalize(chapter.type)} • ${chapter.estimatedTime} min',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? AppTheme.textSecondary : Colors.grey,
                  ),
                ),
             ],
          ),
        ),
        trailing: isUnlocked && !isCompleted
            ? ElevatedButton(
                onPressed: () {
                   context.push('/modules/$moduleId/chapter/${chapter.id}');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppTheme.darkBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start', style: TextStyle(fontSize: 12)),
              )
            : null,
        onTap: isUnlocked ? () => context.push('/modules/$moduleId/chapter/${chapter.id}') : null,
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch(type.toLowerCase()) {
      case 'video': return Icons.play_circle_outline;
      case 'audio': return Icons.headphones_outlined;
      case 'pdf': return Icons.picture_as_pdf_outlined;
      default: return Icons.article_outlined;
    }
  }

  String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';
}
