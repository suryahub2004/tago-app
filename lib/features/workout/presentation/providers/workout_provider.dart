import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/workout_repository.dart';
import '../../data/models/workout_models.dart';

final workoutProvider = StateNotifierProvider<WorkoutNotifier, AsyncValue<List<WorkoutPlan>>>((ref) {
  return WorkoutNotifier(ref.watch(workoutRepositoryProvider));
});

class WorkoutNotifier extends StateNotifier<AsyncValue<List<WorkoutPlan>>> {
  final WorkoutRepository _repository;

  WorkoutNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPlans();
  }

  Future<void> loadPlans() async {
    state = const AsyncValue.loading();
    try {
      final plans = await _repository.getPlans();
      state = AsyncValue.data(plans);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createPlan(Map<String, dynamic> planData) async {
    await _repository.createPlan(planData);
    await loadPlans();
  }

  Future<void> logWorkout(Map<String, dynamic> logData) async {
    await _repository.logWorkout(logData);
  }
}
