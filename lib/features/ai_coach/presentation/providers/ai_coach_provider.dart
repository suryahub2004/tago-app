import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ai_coach_repository.dart';
import '../../data/models/ai_models.dart';

final aiCoachProvider = StateNotifierProvider<AiCoachNotifier, AsyncValue<AiCoachResponse>>((ref) {
  return AiCoachNotifier(ref.watch(aiCoachRepositoryProvider));
});

class AiCoachNotifier extends StateNotifier<AsyncValue<AiCoachResponse>> {
  final AiCoachRepository _repository;

  AiCoachNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInsights();
  }

  Future<void> loadInsights() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.getInsights();
      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshInsights() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.refreshInsights();
      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String> askQuestion(String question) async {
    return _repository.askQuestion(question);
  }

  Future<void> voteInsight(String insightId, bool thumbsUp) async {
    await _repository.trackInteraction(insightId, thumbsUp ? 'thumbs_up' : 'thumbs_down');
    
    final current = state.value;
    if (current == null) return;
    
    final updatedInsights = current.insights.map((i) {
      if (i.id != insightId) return i;
      return i.copyWith(userVoted: thumbsUp);
    }).toList();
    
    state = AsyncValue.data(current.copyWith(insights: updatedInsights));
  }

  Future<void> trackClick(String insightId) async {
    _repository.trackInteraction(insightId, 'click').catchError((_) {});
  }
}
