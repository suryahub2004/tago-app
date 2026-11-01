import '../../../../core/network/api_client.dart';
import 'models/ai_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiCoachRepositoryProvider = Provider<AiCoachRepository>((ref) {
  return AiCoachRepository(ref.watch(apiClientProvider));
});

class AiCoachRepository {
  final ApiClient _api;
  AiCoachRepository(this._api);

  Future<AiCoachResponse> getInsights() async {
    final res = await _api.getMap('/ai-coach/insights');
    return AiCoachResponse.fromJson(res);
  }

  Future<AiCoachResponse> refreshInsights() async {
    final res = await _api.postMap('/ai-coach/insights/refresh', data: {});
    return AiCoachResponse.fromJson(res);
  }

  Future<String> askQuestion(String question) async {
    final res = await _api.postMap('/ai-coach/ask', data: {'question': question});
    return res['answer'] as String;
  }

  Future<WorkoutSuggestion> getWorkoutSuggestion() async {
    final res = await _api.getMap('/ai-coach/workout-suggestion');
    return WorkoutSuggestion.fromJson(res);
  }

  Future<void> trackInteraction(String insightId, String type) async {
    await _api.postMap('/ai-coach/insights/$insightId/interact', data: {'type': type});
  }
}
