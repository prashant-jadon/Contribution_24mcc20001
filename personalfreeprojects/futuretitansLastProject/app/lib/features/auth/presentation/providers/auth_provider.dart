import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/token_storage.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

// Defines the possible states for authentication
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  late AuthRepository _repository;
  late TokenStorage _tokenStorage;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);
    Future.microtask(() => checkAuthStatus());
    return AuthState(status: AuthStatus.initial);
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _tokenStorage.getToken();
      if (token != null) {
        // Fetch profile to verify token validity and get user data
        final user = await _repository.getProfile();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      // Token likely expired or invalid
      await _tokenStorage.clearTokens();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session expired. Please log in again.',
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.login(email, password);
      // Fetch full profile since login endpoint might return a partial user object
      final user = await _repository.getProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signup({
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
     state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.signup(
        name: name,
        email: email,
        phone: phone,
        school: school,
        city: city,
        country: country,
        password: password,
        confirmPassword: confirmPassword,
        schoolSlug: schoolSlug,
      );
      // Fetch full profile since signup endpoint might return a partial user object
      final user = await _repository.getProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repository.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> updateProfile({
    String? name,
    String? bio,
    dynamic profilePicture, // using dynamic because it will be dart:io File
  }) async {
    try {
      final updatedUser = await _repository.updateProfile(
        name: name,
        bio: bio,
        profilePicture: profilePicture,
      );
      // Immediately update the app state with the new user object
      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      // Don't change authentication status, just record the error temporarily if needed
      // Or we can just throw it so the UI can catch it
      throw Exception(e.toString());
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _repository.forgotPassword(email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

