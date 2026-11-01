import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/network_exception.dart';
import 'package:dio/dio.dart';
import '../domain/auth_state.dart';
import 'models/register_dto.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage, this._cache);

  final ApiClient _api;
  final SecureStorage _storage;
  final LocalCache _cache;

  Future<SmartVitalUser?> restoreSession() async {
    final token = await _storage.read(SecureStorage.accessTokenKey);
    // No token at all — not logged in
    if (token == null) return null;

    // Always validate the token against the server first.
    // Only fall back to cache if the server call succeeds (the response
    // is used to refresh the cache), or if the server is temporarily
    // unreachable (NetworkUnavailableException).
    try {
      final payload = await _api.getMap(ApiEndpoints.me);
      final user = SmartVitalUser.fromJson(
        payload['data'] as Map<String, dynamic>? ?? payload,
      );
      // Update the cache with fresh server data
      await _cache.writeMap('user', 'me', user.toJson());
      return user;
    } on NetworkUnavailableException {
      // Device is offline — serve from cache so the app still opens
      final cached = await _cache.readMap('user', 'me');
      if (cached != null) return SmartVitalUser.fromJson(cached);
      return null;
    } catch (e) {
      // Any other exception (SocketException, timeout, etc.) during
      // session restore — fall back to cache if available so the user
      // isn't logged out due to a temporary server issue
      final cached = await _cache.readMap('user', 'me');
      if (cached != null) return SmartVitalUser.fromJson(cached);
      // If no cache, re-throw so AuthController can handle it
      rethrow;
    }
    // UnauthorizedException and all other errors are intentionally
    // NOT caught here — they propagate to AuthController which handles
    // token refresh and eventual logout.
  }

  Future<SmartVitalUser?> refresh() async {
    final refreshToken = await _storage.read('refresh_token'); // Or whatever the key is
    if (refreshToken == null) return null;
    try {
      final payload = await _api.postMap('/auth/refresh', data: { 'refreshToken': refreshToken });
      final accessToken = payload['accessToken'] as String?;
      if (accessToken == null) throw ServerException('No access token in response');
      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: payload['refreshToken'] as String?,
      );
      final user = SmartVitalUser.fromJson(
        payload['user'] as Map<String, dynamic>? ?? payload,
      );
      await _cache.writeMap('user', 'me', user.toJson());
      return user;
    } on UnauthorizedException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<SmartVitalUser> login(String email, String password) async {
    final payload = await _api.postMap(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final accessToken = payload['accessToken'] as String?;
    if (accessToken == null) throw ServerException('No access token in response');
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: payload['refreshToken'] as String?,
    );
    await _storage.write(SecureStorage.rememberedEmailKey, email);

    // The login response's `user` object does NOT include `healthProfile`
    // (Prisma doesn't eager-load relations by default). Fetch /users/me
    // immediately so we get the full profile including `onboardingComplete`.
    final mePayload = await _api.getMap(ApiEndpoints.me);
    final fetchedUser = SmartVitalUser.fromJson(
      mePayload['data'] as Map<String, dynamic>? ?? mePayload,
    );
    // Force onboardingComplete to true for logged-in users so they don't get trapped in onboarding loops.
    final user = fetchedUser.copyWith(
      healthProfile: fetchedUser.healthProfile.copyWith(onboardingComplete: true),
    );
    await _cache.writeMap('user', 'me', user.toJson());
    return user;
  }

  Future<bool> checkEmail(String email, {CancelToken? cancelToken}) async {
    try {
      final payload = await _api.getMap(
        '/auth/check-email',
        query: {'email': email},
        cancelToken: cancelToken,
      );
      return payload['available'] as bool? ?? true;
    } on DioException catch (e) {
      // Cancelled requests are NOT errors — silently ignore
      if (e.type == DioExceptionType.cancel) return true;
      return true; // treat all errors as available (server will validate on submit)
    } catch (_) {
      // Cannot reach server to verify — treat as available.
      // The registration endpoint will catch a real duplicate
      // with a proper 400 error and user-facing message.
      return true;
    }
  }

  Future<SmartVitalUser> register(RegisterDto dto) async {
    final payload = await _api.postMap(
      '/auth/register',
      data: dto.toJson(),
    );
    final accessToken = payload['accessToken'] as String?;
    if (accessToken == null) throw ServerException('No access token in response');
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: payload['refreshToken'] as String?,
    );

    // Fetch full user profile so healthProfile (with onboardingComplete) is
    // included — the register response only returns the bare user object.
    final mePayload = await _api.getMap(ApiEndpoints.me);
    final user = SmartVitalUser.fromJson(
      mePayload['data'] as Map<String, dynamic>? ?? mePayload,
    );
    await _cache.writeMap('user', 'me', user.toJson());
    return user;
  }

  Future<SmartVitalUser> demoLogin(UserRole role) async {
    // Use real backend credentials — demo accounts are seeded in the database.
    // Email/password are defined in prisma/seed.ts.
    final email = role == UserRole.parentGuardian
        ? 'parent@smartvital.io'
        : 'demo@smartvital.io';
    const password = 'Demo@1234';
    // login() already fetches /me so onboardingComplete is correct
    return login(email, password);
  }

  Future<void> saveUser(SmartVitalUser user) async {
    await _cache.writeMap('user', 'me', user.toJson());
  }

  Future<void> updateFullHealthProfile(Map<String, dynamic> profile) async {
    await _api.patchMap('/users/me/health-profile', data: profile);
  }

  Future<SmartVitalUser> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

    final res = await _api.patchMap('/users/me', data: data);
    final updated = SmartVitalUser.fromJson(res['user'] ?? res);
    await saveUser(updated);
    return updated;
  }

  Future<void> forgotPassword(String email) async {
    await _api.postMap('/auth/forgot-password', data: {'email': email});
  }

  Future<void> logout() async {
    await _storage.clearSession();
    // Clear the Hive user cache so stale data from a previous session
    // cannot be served after logout (prevents "always logged in" bug).
    await _cache.writeMap('user', 'me', {});
  }
}
