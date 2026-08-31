import '../../models/workout_entry.dart';
import 'pr.dart';

class ExerciseHistoryPoint {
  final DateTime date;
  final double bestWeightKg;
  final int bestReps;
  final double estimatedOneRepMax;

  const ExerciseHistoryPoint({
    required this.date,
    required this.bestWeightKg,
    required this.bestReps,
    required this.estimatedOneRepMax,
  });
}

/// Builds a most-recent-first per-session history for one exercise (matched
/// by catalog id), collapsing each session to its single best set by
/// estimated 1RM — so a session with several sets of the same lift still
/// contributes one point, not several.
List<ExerciseHistoryPoint> buildExerciseHistory({
  required List<WorkoutEntry> workouts,
  required String exerciseId,
}) {
  final points = <ExerciseHistoryPoint>[];
  for (final workout in workouts) {
    ExerciseHistoryPoint? best;
    for (final log in workout.exercises) {
      if (log.exerciseId != exerciseId) continue;
      for (final s in log.sets) {
        if (s.isWarmup) continue;
        final est =
            SetResult(weightKg: s.weightKg, reps: s.reps).estimatedOneRepMax;
        if (best == null || est > best.estimatedOneRepMax) {
          best = ExerciseHistoryPoint(
            date: workout.date,
            bestWeightKg: s.weightKg,
            bestReps: s.reps,
            estimatedOneRepMax: est,
          );
        }
      }
    }
    if (best != null) points.add(best);
  }
  points.sort((a, b) => b.date.compareTo(a.date));
  return points;
}
