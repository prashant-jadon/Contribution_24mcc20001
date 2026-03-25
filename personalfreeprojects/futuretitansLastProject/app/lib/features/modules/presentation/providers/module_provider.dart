import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/module_model.dart';
import '../../data/repositories/module_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final modulesProvider = FutureProvider.autoDispose<List<ModuleModel>>((ref) async {
  // Watch auth state — this makes the provider automatically re-run
  // whenever auth status changes (e.g. login, logout)
  final authState = ref.watch(authControllerProvider);
  if (authState.status != AuthStatus.authenticated) {
    return []; // Not logged in yet, return empty
  }
  final repository = ref.watch(moduleRepositoryProvider);
  return repository.getStudentModules();
});

// A provider to fetch a specific chapter
final chapterProvider = FutureProvider.family<ChapterModel, String>((ref, paramString) async {
  final repository = ref.watch(moduleRepositoryProvider);
  final parts = paramString.split('|');
  return repository.getChapterDetails(parts[0], parts[1]);
});
