/// A curated sample workout plan (see data/sample_workout_plans.dart).
/// These are fixed templates for browsing/reference — building and saving
/// custom plans is a future phase.
class PlannedExerciseTemplate {
  final String exerciseId;
  final int sets;
  final int targetReps;
  final bool isTimed;

  const PlannedExerciseTemplate({
    required this.exerciseId,
    required this.sets,
    required this.targetReps,
    this.isTimed = false,
  });
}

class WorkoutPlanTemplate {
  final String id;
  final String name;
  final String focus;
  final List<PlannedExerciseTemplate> exercises;

  const WorkoutPlanTemplate({
    required this.id,
    required this.name,
    required this.focus,
    required this.exercises,
  });

  /// Rough estimate: ~2.5 minutes per working set, including rest.
  int get estimatedMinutes =>
      (exercises.fold<int>(0, (sum, e) => sum + e.sets) * 2.5).round();
}
