import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/chat_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

final chatRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ChatRepository(dio: dio);
});

class ChatRepository {
  final Dio _dio;

  ChatRepository({required Dio dio}) : _dio = dio;

  Future<ChatHistoryModel> getChatHistory(String moduleId, String chapterId) async {
    try {
      String url;
      if (moduleId == 'global') {
        url = ApiConstants.globalChatHistory;
      } else {
        url = '${ApiConstants.chatBase}/$moduleId/chapters/$chapterId/history';
      }
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return ChatHistoryModel.fromJson(response.data);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load chat history');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String moduleId, String chapterId, String message) async {
    try {
      String url;
      if (moduleId == 'global') {
        url = ApiConstants.globalChatMessage;
      } else {
        url = '${ApiConstants.chatBase}/$moduleId/chapters/$chapterId/message';
      }
      final response = await _dio.post(
        url,
        data: {'message': message},
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to send message');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> finishChapter(String moduleId, String chapterId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.chatBase}/$moduleId/chapters/$chapterId/finish',
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to finish chapter');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> completeChapter(String moduleId, String chapterId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.chatBase}/$moduleId/chapters/$chapterId/complete',
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to complete chapter');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> getSSI() async {
    try {
      final response = await _dio.get('${ApiConstants.chatBase}/ssi');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load SSI');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> getReport() async {
    try {
      final response = await _dio.get('${ApiConstants.chatBase}/report');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load report');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message ?? 'Network error');
    }
  }
}
