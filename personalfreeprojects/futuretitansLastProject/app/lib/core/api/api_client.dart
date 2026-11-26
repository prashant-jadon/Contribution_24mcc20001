import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 35), // Ai responses take time
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  final tokenStorage = ref.watch(tokenStorageProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
          // Token expired, attempt refresh
          final refreshToken = await tokenStorage.getRefreshToken();
          if (refreshToken != null) {
            try {
              // Creating a new dio instance for refresh request to avoid interceptor loop
              final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
              final response = await refreshDio.post(
                ApiConstants.refresh,
                data: {'token': refreshToken},
              );
              
              if (response.statusCode == 200 && response.data['accessToken'] != null) {
                final newAccessToken = response.data['accessToken'];
                await tokenStorage.saveTokens(token: newAccessToken, refreshToken: refreshToken);
                
                // Retry original request
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                final cloneReq = await dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(cloneReq);
              }
            } catch (_) {
              // Refresh failed, clear tokens and pass error
              await tokenStorage.clearTokens();
            }
          } else {
            // No refresh token available, just clear
            await tokenStorage.clearTokens();
          }
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
