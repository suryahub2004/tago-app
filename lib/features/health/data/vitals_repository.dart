import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class VitalsRepository {
  VitalsRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getSummary({String period = 'today'}) async {
    return _api.getMap('/vitals/summary', query: {'period': period});
  }

  Future<List<Map<String, dynamic>>> getHistory(String type, {String period = '7d'}) async {
    // Backend returns a plain array — use getList()
    final list = await _api.getList('/vitals/history/$type', query: {'period': period});
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getReport({String period = 'daily'}) async {
    return _api.getMap('/vitals/report', query: {'period': period});
  }

  Future<Map<String, dynamic>> getReadinessForecast() async {
    return _api.getMap('/vitals/readiness-forecast');
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(ref.watch(apiClientProvider));
});
