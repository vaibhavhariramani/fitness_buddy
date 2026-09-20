import '../../models/workout_entry.dart';
import 'date_utils.dart';

/// Combined exercises/sets/PRs across every workout logged on [now]'s
/// calendar date (today, by default) — shared by the dashboard's "today"
/// card and a friend's shared-progress "today's training" card.
class TodaysWorkoutSummary {
  final int exerciseCount;
  final int setCount;
  final int prCount;

  const TodaysWorkoutSummary({
    required this.exerciseCount,
    required this.setCount,
    required this.prCount,
  });
}

/// Null when nothing was logged that day.
TodaysWorkoutSummary? summarizeTodaysWorkouts(
  List<WorkoutEntry> workouts, {
  DateTime? now,
}) {
  final today = dateOnly(now ?? DateTime.now());
  final todays = workouts.where((w) => dateOnly(w.date) == today).toList();
  if (todays.isEmpty) return null;

  var exerciseCount = 0;
  var setCount = 0;
  var prCount = 0;
  for (final w in todays) {
    exerciseCount += w.exercises.length;
    for (final e in w.exercises) {
      setCount += e.sets.length;
      if (e.isPr) prCount++;
    }
  }
  return TodaysWorkoutSummary(
    exerciseCount: exerciseCount,
    setCount: setCount,
    prCount: prCount,
  );
}
