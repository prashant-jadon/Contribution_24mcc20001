import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/module_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

final moduleRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ModuleRepository(dio: dio);
});

class ModuleRepository {
  final Dio _dio;

  ModuleRepository({required Dio dio}) : _dio = dio;

  Future<List<ModuleModel>> getStudentModules() async {
    try {
      final response = await _dio.get(ApiConstants.modules);
      if (response.statusCode == 200) {
        // Backend returns a flat JSON array of modules with userProgress inline
        final List modulesData = response.data is List ? response.data : [];
        return modulesData.map((m) => ModuleModel.fromJson(m)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load modules');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }

  Future<ModuleModel> getModuleById(String moduleId) async {
    try {
      final response = await _dio.get('${ApiConstants.modules}/$moduleId');
      if (response.statusCode == 200) {
        return ModuleModel.fromJson(response.data);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load module');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }

  Future<ChapterModel> getChapterDetails(String moduleId, String chapterId) async {
    try {
      final response = await _dio.get('${ApiConstants.modules}/$moduleId/chapters/$chapterId');
      if (response.statusCode == 200) {
        return ChapterModel.fromJson(response.data);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load chapter');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }
}
