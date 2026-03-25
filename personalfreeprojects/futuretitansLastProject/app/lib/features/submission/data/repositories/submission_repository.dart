import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/submission_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

final submissionRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return SubmissionRepository(dio: dio);
});

class SubmissionRepository {
  final Dio _dio;

  SubmissionRepository({required Dio dio}) : _dio = dio;

  Future<List<SubmissionModel>> getMySubmissions() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/api/submissions/my');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => SubmissionModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load submissions');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }

  Future<SubmissionModel> createSubmission(SubmissionModel submission) async {
    try {
      // In a real app, multipart/form-data would be used for file uploads
      // For this structural phase we'll stick to basic JSON POST for text fields
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/submissions',
        data: submission.toJson(),
      );
      if (response.statusCode == 201) {
        return SubmissionModel.fromJson(response.data['data']);
      } else {
         throw Exception(response.data['error'] ?? 'Failed to submit');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }
}
