import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/services/api_service.dart';
import '../core/services/onesignal_service.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  UserModel? _user;
  ProfileModel? _profile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  ProfileModel? get profile => _profile;
  bool get hasProfile => _profile != null && _profile!.isComplete;
  bool get hasCompleteProfile => _profile != null && _profile!.isComplete;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null) {
        await loadUser();
      }
    } catch (e) {
      _isAuthenticated = false;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        final tokens = data['tokens'];

        await _storage.write(key: AppConstants.tokenKey, value: tokens['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: tokens['refreshToken']);

        _user = UserModel.fromJson(data['user']);
        if (data['profile'] != null) {
          try {
            _profile = ProfileModel.fromJson(data['profile']);
            debugPrint('Profile loaded from login: isComplete=${_profile!.isComplete}');
          } catch (e) {
            debugPrint('Error parsing profile from login response: $e');
            _profile = null;
          }
        } else {
          _profile = null;
        }
        _isAuthenticated = true;

        // Always reload user to get latest profile data
        await loadUser();

        // Send OneSignal player ID to backend
        await _sendOneSignalPlayerId();

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = response.data['message'] ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _handleDioError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String email, String password, String name, String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.signup(email, password, name, username);
      if (response.statusCode == 201 && response.data['success']) {
        final data = response.data['data'];
        final tokens = data['tokens'];

        await _storage.write(key: AppConstants.tokenKey, value: tokens['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: tokens['refreshToken']);

        _user = UserModel.fromJson(data['user']);
        _isAuthenticated = true;

        // Send OneSignal player ID to backend
        await _sendOneSignalPlayerId();

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = _extractErrorMessage(response.data);
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _handleDioError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Signup failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleSignIn(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.googleSignIn(idToken);
      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        final tokens = data['tokens'];

        await _storage.write(key: AppConstants.tokenKey, value: tokens['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: tokens['refreshToken']);

        _user = UserModel.fromJson(data['user']);
        if (data['profile'] != null) {
          _profile = ProfileModel.fromJson(data['profile']);
        }
        _isAuthenticated = true;

        // Send OneSignal player ID to backend
        await _sendOneSignalPlayerId();

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = response.data['message'] ?? 'Google sign in failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _handleDioError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google sign in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200 && response.data['success'];
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      debugPrint('Load user response: ${response.statusCode} - ${response.data}');
      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        _user = UserModel.fromJson(data['user']);
        if (data['profile'] != null) {
          try {
            debugPrint('Profile data received: ${data['profile']}');
            _profile = ProfileModel.fromJson(data['profile']);
            debugPrint('Profile loaded successfully: isComplete=${_profile!.isComplete}, id=${_profile!.id}');
          } catch (e, stackTrace) {
            debugPrint('Error parsing profile: $e');
            debugPrint('Stack trace: $stackTrace');
            debugPrint('Profile JSON that failed: ${data['profile']}');
            _profile = null;
          }
        } else {
          debugPrint('No profile in response data');
          _profile = null;
        }
        _isAuthenticated = true;
        
        // Send OneSignal player ID to backend
        await _sendOneSignalPlayerId();
        
        notifyListeners();
      } else {
        debugPrint('Failed to load user: ${response.data['message']}');
        _isAuthenticated = false;
        _user = null;
        _profile = null;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user: $e');
      debugPrint('Stack trace: $stackTrace');
      _isAuthenticated = false;
      _user = null;
      _profile = null;
      notifyListeners();
    }
  }

  Future<bool> setupProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.setupProfile(profileData);
      
      debugPrint('Profile setup response status: ${response.statusCode}');
      debugPrint('Profile setup response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final isSuccess = responseData['success'] == true;
        
        if (isSuccess) {
          // Profile was created, now reload to get the complete profile with calculated strength
          await loadUser();
          
          // Verify profile is loaded and check completion
          if (_profile != null) {
            debugPrint('Profile loaded: isComplete=${_profile!.isComplete}');
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            // Profile was created but couldn't be loaded
            debugPrint('Profile created but not loaded');
            _isLoading = false;
            notifyListeners();
            return true; // Still return true as profile was created
          }
        } else {
          _errorMessage = responseData['message'] ?? 'Profile setup failed';
          debugPrint('Profile setup failed: $_errorMessage');
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final responseData = response.data;
        _errorMessage = responseData['message'] ?? 'Profile setup failed';
        debugPrint('Profile setup failed with status ${response.statusCode}: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      debugPrint('DioException during profile setup: ${e.response?.data}');
      _handleDioError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Generic error during profile setup: $e');
      _errorMessage = 'Profile setup failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void updateProfile(ProfileModel updatedProfile) {
    _profile = updatedProfile;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        await _apiService.logout(refreshToken);
      }
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Logout from OneSignal
    try {
      await OneSignalService().logout();
    } catch (e) {
      debugPrint('Error logging out from OneSignal: $e');
    }

    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);

    _isAuthenticated = false;
    _user = null;
    _profile = null;
    notifyListeners();
  }

  void _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      _errorMessage = _extractErrorMessage(data);
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      _errorMessage = 'Connection timeout. Please check your internet.';
    } else {
      _errorMessage = 'Network error. Please check your connection.';
    }
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    if (data['errors'] != null && (data['errors'] as List).isNotEmpty) {
      return data['errors'][0]['message'] ?? data['message'] ?? 'An error occurred';
    }
    return data['message'] ?? 'An error occurred';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _sendOneSignalPlayerId() async {
    try {
      final oneSignalService = OneSignalService();
      if (oneSignalService.isInitialized && oneSignalService.playerId != null) {
        await oneSignalService.sendPlayerIdToBackend();
        // Also set user ID for OneSignal
        if (_user?.id != null) {
          await oneSignalService.setUserId(_user!.id);
        }
      }
    } catch (e) {
      debugPrint('Error sending OneSignal player ID: $e');
    }
  }
}

