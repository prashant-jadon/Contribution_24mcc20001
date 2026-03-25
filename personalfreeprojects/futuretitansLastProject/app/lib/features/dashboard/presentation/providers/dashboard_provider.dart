import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;
  final int points;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.points,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      icon: json['icon'] ?? '',
      points: json['points'] ?? 0,
    );
  }
}

final dashboardRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepository(dio: dio);
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository({required Dio dio}) : _dio = dio;

  Future<List<AchievementModel>> getRecentAchievements() async {
    try {
      final response = await _dio.get(ApiConstants.achievements);
      if (response.statusCode == 200) {
        final List data = response.data['achievements'] ?? [];
        return data.map((e) {
          final achievementData = e['achievementId'] ?? e;
          return AchievementModel.fromJson(achievementData);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final recentAchievementsProvider = FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.status != AuthStatus.authenticated) {
    return [];
  }
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getRecentAchievements();
});
