import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(ref.watch(secureStorageProvider));
});

class BiometricService {
  static const _enabledKey = 'biometric_lock_enabled';
  final LocalAuthentication _auth = LocalAuthentication();
  final SecureStorage _storage;

  BiometricService(this._storage);

  Future<bool> get isAvailable async {
    final canCheck = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();
    return canCheck && isDeviceSupported;
  }

  Future<bool> get isEnabled async {
    final val = await _storage.read(_enabledKey);
    return val == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(_enabledKey, enabled.toString());
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access SmartVital',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
