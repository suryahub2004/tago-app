import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const rememberedEmailKey = 'remembered_email';
  static const healthPermissionKey = 'health_permission_enabled';

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key).timeout(const Duration(seconds: 1));
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> write(String key, String value) async {
    _memoryFallback[key] = value;
    try {
      await _storage.write(key: key, value: value).timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  Future<void> delete(String key) async {
    _memoryFallback.remove(key);
    try {
      await _storage.delete(key: key).timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await write(accessTokenKey, accessToken);
    if (refreshToken != null) {
      await write(refreshTokenKey, refreshToken);
    }
  }

  Future<void> clearSession() async {
    await delete(accessTokenKey);
    await delete(refreshTokenKey);
  }
}
