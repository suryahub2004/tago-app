import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_repository.dart';
import '../../data/models/register_dto.dart';
import '../../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
    ref.watch(localCacheProvider),
  );
});

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref.watch(secureStorageProvider));
});

final currentUserProvider = Provider<SmartVitalUser?>(
  (ref) => ref.watch(authProvider).user,
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._storage) : super(const AuthState());

  final AuthRepository _repository;
  final SecureStorage _storage;

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isRestoring: true, clearError: true);
    final token = await _storage.read(SecureStorage.accessTokenKey);
    if (token == null) {
      state = const AuthState(isRestoring: false);
      return;
    }
    
    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        state = state.copyWith(user: user, isRestoring: false);
      } else {
        state = const AuthState(isRestoring: false);
      }
    } on UnauthorizedException {
      await _refreshToken();
    } catch (_) {
      state = const AuthState(isRestoring: false);
    }
  }

  Future<void> _refreshToken() async {
    try {
      final user = await _repository.refresh();
      if (user != null) {
        state = state.copyWith(user: user, isRestoring: false);
      } else {
        await logout();
      }
    } catch (_) {
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false, errorMessage: 'Incorrect email or password');
    } on TooManyRequestsException {
      state = state.copyWith(isLoading: false, errorMessage: 'Too many attempts — try again in 1 minute');
    } on NetworkUnavailableException {
      state = state.copyWith(isLoading: false, errorMessage: 'No internet connection');
    } catch (error) {
      String message;
      if (error is ServerException) {
        message = error.message.isNotEmpty
            ? error.message
            : 'Something went wrong. Please try again.';
      } else if (error is ValidationException) {
        message = 'Please check your email and password format.';
      } else {
        message = 'Sign in failed. Please try again.';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  Future<void> register(RegisterDto dto) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.register(dto);
      state = state.copyWith(user: user, isLoading: false);
    } on NetworkUnavailableException {
      state = state.copyWith(isLoading: false, errorMessage: 'No internet connection');
    } catch (error) {
      String message;
      if (error is ServerException) {
        message = error.message.isNotEmpty
            ? error.message
            : 'Registration failed. Please try again.';
      } else {
        message = 'Registration failed. Please try again.';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  Future<void> demoLogin(UserRole role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.demoLogin(role);
      state = state.copyWith(user: user, isLoading: false, isRestoring: false);
    } on UnauthorizedException {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
          'Demo account not found. Run: npx prisma db seed in the API directory.',
      );
    } on NetworkUnavailableException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No internet connection',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Demo login failed: ${e.toString()}',
      );
    }
  }

  Future<void> updateHealthProfile(HealthProfile profile) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(healthProfile: profile);
    await _repository.saveUser(updated);
    state = state.copyWith(user: updated);
  }

  Future<void> saveFullHealthProfile(Map<String, dynamic> data) async {
    try {
      await _repository.updateFullHealthProfile(data);
    } catch (e) {
      // Non-fatal for demo mode — log but don't crash
      debugPrint('saveFullHealthProfile failed: $e');
    }
  }

  Future<void> updateUserProfile({String? name, String? phone}) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _repository.updateProfile(name: name, phone: phone);
      state = state.copyWith(user: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.forgotPassword(email);
      state = state.copyWith(isLoading: false);
    } on NotFoundException {
      state = state.copyWith(isLoading: false, errorMessage: 'Password reset is coming soon. Contact support.');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    await _storage.clearSession();
    state = const AuthState(isRestoring: false);
  }
}
