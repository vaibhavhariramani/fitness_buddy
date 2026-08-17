import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/workout_entry.dart';
import 'workouts_tab.dart';

/// The most recent logged set of this exercise (matched by catalog
/// exerciseId), or null if it's never been logged with a linked id.
/// [workoutHistoryProvider] is already ordered most-recent-first.
final previousPerformanceProvider = Provider.family<ExerciseLog?, String>((
  ref,
  exerciseId,
) {
  final history = ref.watch(workoutHistoryProvider).valueOrNull ?? const [];
  for (final workout in history) {
    for (final log in workout.exercises) {
      if (log.exerciseId == exerciseId) return log;
    }
  }
  return null;
});
