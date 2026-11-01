import '../../../core/network/api_client.dart';
import 'models/alert.dart';

class AlertRepository {
  final ApiClient _api;

  AlertRepository(this._api);

  Future<List<AlertModel>> getAlerts() async {
    final response = await _api.getMap('/alerts');
    final data = response['data'] as List?;
    if (data == null) return [];
    return data.map((e) => AlertModel.fromJson(e)).toList();
  }

  Future<void> acknowledgeAlert(String alertId) async {
    await _api.patchMap('/alerts/$alertId/acknowledge');
  }
}
