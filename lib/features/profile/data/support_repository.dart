import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class SupportRepository {
  SupportRepository(this._api);
  final ApiClient _api;

  Future<void> submitTicket(Map<String, dynamic> data) async {
    await _api.postMap('/support', data: data);
  }

  Future<List<Map<String, dynamic>>> getMyTickets() async {
    final res = await _api.getMap('/support/my-tickets');
    return List<Map<String, dynamic>>.from(res['data'] ?? res['tickets'] ?? []);
  }
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});
