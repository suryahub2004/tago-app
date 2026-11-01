import '../../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(apiClientProvider));
});

class DeviceRepository {
  final ApiClient _api;
  DeviceRepository(this._api);

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final List<dynamic> res = await _api.getList('/devices/my-devices');
    if (res.isEmpty) return {};
    return res.first as Map<String, dynamic>;
  }

  Future<void> checkFirmwareUpdate(String id) async {
    await _api.getMap('/devices/$id/firmware-check');
  }
}
