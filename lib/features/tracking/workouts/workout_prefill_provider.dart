import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutPrefill {
  final String name;
  final String muscleGroup;

  const WorkoutPrefill({required this.name, required this.muscleGroup});
}

/// Set by the Exercises feature's "Add to Workout" dialog before pushing to
/// /tracking; consumed once by WorkoutsTab to auto-open a pre-filled
/// LogWorkoutSheet.
final pendingWorkoutPrefillProvider = StateProvider<WorkoutPrefill?>(
  (ref) => null,
);
