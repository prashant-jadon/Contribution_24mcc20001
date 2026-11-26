import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';

  Future<void> saveTokens({required String token, String? refreshToken}) async {
    await _storage.write(key: _keyToken, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  Future<String?> getToken() async => await _storage.read(key: _keyToken);
  
  Future<String?> getRefreshToken() async => await _storage.read(key: _keyRefreshToken);

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}
