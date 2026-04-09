import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/token_storage.dart';

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(dio: dio, tokenStorage: tokenStorage);
});

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository({required Dio dio, required TokenStorage tokenStorage}) 
      : _dio = dio, _tokenStorage = tokenStorage;

  String _getErrorMessage(dynamic data, [String defaultMsg = 'Network error']) {
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      return data['error'].toString();
    }
    return defaultMsg;
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        await _tokenStorage.saveTokens(
          token: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return UserModel.fromJson(data['user']);
      } else {
        throw Exception(_getErrorMessage(response.data, 'Login failed'));
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, e.message ?? 'Network error'));
    }
  }

  Future<UserModel> signup({
    required String name,
    required String email,
    required String phone,
    required String school,
    required String city,
    required String country,
    required String password,
    required String confirmPassword,
    String? schoolSlug,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.signup, data: {
        'name': name,
        'email': email,
        'phone': phone,
        'school': school,
        'city': city,
        'country': country,
        'password': password,
        'confirmPassword': confirmPassword,
        if (schoolSlug != null && schoolSlug.isNotEmpty) 'schoolSlug': schoolSlug,
      });

      if (response.statusCode == 201) {
         final data = response.data;
        await _tokenStorage.saveTokens(
          token: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return UserModel.fromJson(data['user']);
      } else {
        throw Exception(_getErrorMessage(response.data, 'Signup failed'));
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, e.message ?? 'Network error'));
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception(_getErrorMessage(response.data, 'Failed to load profile'));
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, e.message ?? 'Network error'));
    }
  }

  Future<Map<String, dynamic>> checkCompletionStatus() async {
    try {
      final response = await _dio.get(ApiConstants.checkCompletion);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(_getErrorMessage(response.data, 'Failed to check completion status'));
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, e.message ?? 'Network error'));
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? bio,
    File? profilePicture,
  }) async {
    try {
      dynamic data;
      Options? options;

      if (profilePicture != null) {
        // Send as multipart/form-data
        final formData = FormData.fromMap({
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          'profilePicture': await MultipartFile.fromFile(profilePicture.path),
        });
        data = formData;
        options = Options(contentType: 'multipart/form-data');
      } else {
        // Send as application/json
        data = {
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
        };
      }

      final response = await _dio.put(
        ApiConstants.profile,
        data: data,
        options: options,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception(_getErrorMessage(response.data, 'Update failed'));
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, e.message ?? 'Network error'));
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(ApiConstants.forgotPassword, data: {
        'email': email,
      });

      if (response.statusCode != 200) {
        throw Exception(_getErrorMessage(response.data, 'Failed to send reset email'));
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e.response?.data, e.message ?? 'Network error'));
    }
  }
}
