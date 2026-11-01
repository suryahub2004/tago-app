class Exercise {
  final String id;
  final String name;
  final String category;
  final String? muscleGroup;
  final String? equipment;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;
  final int? restSeconds;
  final String? notes;
  final String? videoUrl;

  Exercise({
    required this.id, required this.name, required this.category, this.muscleGroup,
    this.equipment, this.sets, this.reps, this.durationSeconds, this.weightKg,
    this.restSeconds, this.notes, this.videoUrl
  });
}

class WorkoutDay {
  final String id;
  final int dayOfWeek;
  final String label;
  final bool isRestDay;
  final List<Exercise> exercises;
  final String? notes;

  WorkoutDay({
    required this.id, required this.dayOfWeek, required this.label, required this.isRestDay, required this.exercises, this.notes
  });
}

class WorkoutPlan {
  final String id;
  final String name;
  final String? description;
  final String goal;
  final int durationWeeks;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<WorkoutDay> days;
  final double? completionRate;
  final DateTime createdAt;

  WorkoutPlan({
    required this.id, required this.name, this.description, required this.goal, required this.durationWeeks,
    required this.startDate, this.endDate, required this.isActive, required this.days, this.completionRate, required this.createdAt
  });
}

class ExerciseLog {
  final String exerciseId;
  final int setsCompleted;
  final int repsCompleted;
  final double weightKg;

  ExerciseLog({required this.exerciseId, required this.setsCompleted, required this.repsCompleted, required this.weightKg});
}

class WorkoutLog {
  final String id;
  final String planId;
  final String dayId;
  final DateTime date;
  final bool completed;
  final int? durationMinutes;
  final List<ExerciseLog>? exerciseLogs;
  final double? perceivedEffort;
  final String? notes;
  final double? avgHeartRate;
  final double? peakHeartRate;
  final double? caloriesBurned;
  final double? strain;

  WorkoutLog({
    required this.id, required this.planId, required this.dayId, required this.date, required this.completed,
    this.durationMinutes, this.exerciseLogs, this.perceivedEffort, this.notes,
    this.avgHeartRate, this.peakHeartRate, this.caloriesBurned, this.strain
  });
}
