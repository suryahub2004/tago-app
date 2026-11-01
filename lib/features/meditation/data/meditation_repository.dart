import '../../../../core/network/api_client.dart';
import 'models/meditation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final meditationRepositoryProvider = Provider<MeditationRepository>((ref) {
  return MeditationRepository(ref.watch(apiClientProvider));
});

class MeditationRepository {
  final ApiClient _api;
  MeditationRepository(this._api);

  Future<void> saveSession(Map<String, dynamic> sessionData) async {
    await _api.postMap('/meditation/sessions', data: sessionData);
  }

  Future<List<MeditationSession>> getHistory() async {
    return [];
  }
}
