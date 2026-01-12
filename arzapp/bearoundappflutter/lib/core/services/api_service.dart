import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            final token = await _storage.read(key: AppConstants.tokenKey);
            opts.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success']) {
        final tokens = response.data['data']['tokens'];
        await _storage.write(key: AppConstants.tokenKey, value: tokens['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: tokens['refreshToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============ AUTH APIs ============
  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> signup(String email, String password, String name, String username) async {
    final data = {
      'email': email,
      'password': password,
      'username': username,
    };
    // Only include name if it's not empty (name is collected in profile setup)
    if (name.isNotEmpty) {
      data['name'] = name;
    }
    return await _dio.post('/auth/signup', data: data);
  }

  Future<Response> googleSignIn(String idToken) async {
    return await _dio.post('/auth/google', data: {
      'idToken': idToken,
    });
  }

  Future<Response> forgotPassword(String email) async {
    return await _dio.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/auth/me');
  }

  Future<Response> updateDeviceToken(String playerId, String platform) async {
    return await _dio.post('/auth/device-token', data: {
      'playerId': playerId,
      'platform': platform,
    });
  }

  Future<Response> logout(String refreshToken) async {
    return await _dio.post('/auth/logout', data: {
      'refreshToken': refreshToken,
    });
  }

  // ============ PROFILE APIs ============
  Future<Response> setupProfile(Map<String, dynamic> data) async {
    return await _dio.post('/profile/setup', data: data);
  }

  Future<Response> getProfile() async {
    return await _dio.get('/profile');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put('/profile', data: data);
  }

  Future<Response> uploadPhoto(FormData formData) async {
    return await _dio.post(
      '/profile/photos',
      data: formData,
      options: Options(
        followRedirects: false,
        validateStatus: (status) => status! < 500,
      ),
    );
  }

  Future<Response> deletePhoto(String photoId) async {
    return await _dio.delete('/profile/photos/$photoId');
  }

  Future<Response> reorderPhotos(List<String> photoOrder) async {
    return await _dio.put('/profile/photos/reorder', data: {
      'photoOrder': photoOrder,
    });
  }

  Future<Response> getProfileByUsername(String username) async {
    return await _dio.get('/profile/user/$username');
  }

  Future<Response> getProfileByUserId(String userId) async {
    return await _dio.get('/profile/user-id/$userId');
  }

  // Get public profile by username (for deep links)
  Future<Response> getPublicProfileByUsername(String username) async {
    return await _dio.get('/p/$username');
  }

  Future<Response> getShareInfo() async {
    return await _dio.get('/profile/share');
  }

  Future<Response> getProfileViewers({int days = 7}) async {
    return await _dio.get('/profile/viewers', queryParameters: {'days': days});
  }

  // ============ MESSAGE REQUEST APIs ============
  Future<Response> sendMessageRequest(Map<String, dynamic> data) async {
    return await _dio.post('/requests', data: data);
  }

  Future<Response> getPendingRequests({int page = 1, int limit = 20}) async {
    return await _dio.get('/requests/pending', queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> getSentRequests({int page = 1, int limit = 20, String? status}) async {
    return await _dio.get('/requests/sent', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
  }

  Future<Response> acceptRequest(String requestId) async {
    return await _dio.post('/requests/$requestId/accept');
  }

  Future<Response> rejectRequest(String requestId) async {
    return await _dio.post('/requests/$requestId/reject');
  }

  Future<Response> cancelRequest(String requestId) async {
    return await _dio.delete('/requests/$requestId');
  }

  Future<Response> getRequestStats() async {
    return await _dio.get('/requests/stats');
  }

  // ============ MESSAGE APIs ============
  Future<Response> getConversations({int page = 1, int limit = 20, bool archived = false}) async {
    return await _dio.get('/messages/conversations', queryParameters: {
      'page': page,
      'limit': limit,
      'archived': archived,
    });
  }

  Future<Response> getConversation(String conversationId) async {
    return await _dio.get('/messages/conversations/$conversationId');
  }

  Future<Response> getMessages(String conversationId, {int page = 1, int limit = 50}) async {
    return await _dio.get('/messages/conversations/$conversationId/messages', queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> sendMessage(String conversationId, Map<String, dynamic> data) async {
    return await _dio.post(
      '/messages/conversations/$conversationId/messages',
      data: data,
    );
  }

  Future<Response> addReaction(String messageId, String emoji) async {
    return await _dio.post('/messages/$messageId/reactions', data: {
      'emoji': emoji,
    });
  }

  Future<Response> requestReveal(String conversationId) async {
    return await _dio.post('/messages/conversations/$conversationId/request-reveal');
  }

  Future<Response> revealIdentity(String conversationId, {List<String>? fields}) async {
    return await _dio.post('/messages/conversations/$conversationId/reveal', data: {
      if (fields != null) 'fields': fields,
    });
  }

  Future<Response> muteConversation(String conversationId, {int? duration}) async {
    return await _dio.post('/messages/conversations/$conversationId/mute', data: {
      if (duration != null) 'duration': duration,
    });
  }

  Future<Response> getUnreadCount() async {
    return await _dio.get('/messages/unread-count');
  }

  // ============ SEARCH APIs ============
  Future<Response> searchUsers(Map<String, dynamic> queryParams) async {
    return await _dio.get('/search', queryParameters: queryParams);
  }

  Future<Response> getSearchSuggestions(String query, {String type = 'all'}) async {
    return await _dio.get('/search/suggestions', queryParameters: {
      'q': query,
      'type': type,
    });
  }

  Future<Response> getPopularSearches() async {
    return await _dio.get('/search/popular');
  }

  // ============ DISCOVERY APIs ============
  Future<Response> getDiscoveryFeed(Map<String, dynamic> queryParams) async {
    return await _dio.get('/discover', queryParameters: queryParams);
  }

  Future<Response> skipProfile(String profileId) async {
    return await _dio.post('/discover/skip/$profileId');
  }

  Future<Response> getFilterOptions() async {
    return await _dio.get('/discover/filters');
  }

  // ============ BLOCK APIs ============
  Future<Response> blockUser(Map<String, dynamic> data) async {
    return await _dio.post('/block', data: data);
  }

  Future<Response> unblockUser(String userId) async {
    return await _dio.delete('/block/$userId');
  }

  Future<Response> getBlockedUsers({int page = 1, int limit = 20}) async {
    return await _dio.get('/block', queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> panicBlock(String userId) async {
    return await _dio.post('/block/panic', data: {
      'userId': userId,
    });
  }

  // ============ REPORT APIs ============
  Future<Response> reportUser(Map<String, dynamic> data) async {
    return await _dio.post('/report', data: data);
  }

  Future<Response> getReportHistory({int page = 1, int limit = 20}) async {
    return await _dio.get('/report/history', queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  // ============ NOTIFICATION APIs ============
  Future<Response> getNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) async {
    return await _dio.get('/notifications', queryParameters: {
      'page': page,
      'limit': limit,
      'unreadOnly': unreadOnly,
    });
  }

  Future<Response> getUnreadNotificationCount() async {
    return await _dio.get('/notifications/unread-count');
  }

  Future<Response> markNotificationAsRead(String notificationId) async {
    return await _dio.post('/notifications/$notificationId/read');
  }

  Future<Response> markAllNotificationsRead() async {
    return await _dio.post('/notifications/read-all');
  }

  Future<Response> deleteNotification(String notificationId) async {
    return await _dio.delete('/notifications/$notificationId');
  }

  Future<Response> getNotificationPreferences() async {
    return await _dio.get('/notifications/preferences');
  }

  Future<Response> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    return await _dio.put('/notifications/preferences', data: {
      'preferences': preferences,
    });
  }


  // ============ SETTINGS APIs ============
  Future<Response> getSettings() async {
    return await _dio.get('/settings');
  }

  Future<Response> updatePrivacySettings(Map<String, dynamic> data) async {
    return await _dio.put('/settings/privacy', data: data);
  }

  Future<Response> changePassword(String currentPassword, String newPassword) async {
    return await _dio.put('/settings/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<Response> changeUsername(String username) async {
    return await _dio.put('/settings/username', data: {
      'username': username,
    });
  }

  Future<Response> exportData() async {
    return await _dio.get('/settings/export');
  }

  Future<Response> deleteAccount(String password, String confirmation) async {
    return await _dio.delete('/settings/account', data: {
      'password': password,
      'confirmation': confirmation,
    });
  }

  // ============ INSIGHTS APIs ============
  Future<Response> getInsights({int days = 30}) async {
    return await _dio.get('/insights', queryParameters: {'days': days});
  }

  Future<Response> getProfileScore() async {
    return await _dio.get('/insights/score');
  }
}

