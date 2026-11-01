import '../../../../core/network/api_client.dart';
import 'models/workout_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(apiClientProvider));
});

class WorkoutRepository {
  final ApiClient _api;
  WorkoutRepository(this._api);

  Future<List<WorkoutPlan>> getPlans() async {
    try {
      final list = await _api.getList('/workout/plans');
      return list.map((e) => _planFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> createPlan(Map<String, dynamic> planData) async {
    await _api.postMap('/workout/plans', data: planData);
  }

  Future<void> logWorkout(Map<String, dynamic> logData) async {
    await _api.postMap('/workout/logs', data: logData);
  }

  Future<List<dynamic>> getExercises() async {
    try {
      return await _api.getList('/workout/exercises');
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getProgress() async {
    try {
      return await _api.getMap('/workout/progress');
    } catch (_) {
      return {};
    }
  }

  static WorkoutPlan _planFromJson(Map<String, dynamic> j) {
    final daysRaw = j['days'] as List<dynamic>? ?? [];
    return WorkoutPlan(
      id:            j['id'] as String? ?? '',
      name:          j['name'] as String? ?? '',
      description:   j['description'] as String?,
      goal:          j['goal'] as String? ?? 'general',
      durationWeeks: (j['durationWeeks'] as num?)?.toInt() ?? 4,
      startDate:     DateTime.tryParse(j['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate:       j['endDate'] != null ? DateTime.tryParse(j['endDate'] as String) : null,
      isActive:      j['isActive'] as bool? ?? false,
      createdAt:     DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      days: daysRaw.map((d) {
        final dm = d as Map<String, dynamic>;
        return WorkoutDay(
          id:         dm['id'] as String? ?? '',
          dayOfWeek:  (dm['dayOfWeek'] as num?)?.toInt() ?? 1,
          label:      dm['label'] as String? ?? '',
          isRestDay:  dm['isRestDay'] as bool? ?? false,
          exercises:  [],
        );
      }).toList(),
    );
  }
}
