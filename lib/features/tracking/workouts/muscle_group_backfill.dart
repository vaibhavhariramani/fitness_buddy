import '../../../models/workout_entry.dart';
import '../../../services/repositories/workout_repo.dart';
import '../../exercises/models/exercise.dart';
import '../../exercises/widgets/add_to_workout_dialog.dart'
    show resolveMuscleGroup;

/// One-time data fix for logs written before an exercise's catalog category
/// was correctly populated (or before it existed in the catalog at all) —
/// those logs baked in a stale `muscleGroup` (often "Full body") that stuck
/// around forever since [ExerciseLog.muscleGroup] is never re-derived on
/// read anywhere except the aggregated stats views. This rewrites the
/// stored value on each affected workout document so raw per-exercise
/// displays (e.g. workout history) show the right muscle group too, not
/// just the aggregates.
///
/// Returns the number of workout documents that needed a fix.
Future<int> backfillWorkoutMuscleGroups({
  required WorkoutRepo workoutRepo,
  required String uid,
  required List<Exercise> catalog,
}) async {
  final byId = {for (final e in catalog) e.id: e};
  final workouts = await workoutRepo.watchAll(uid).first;

  var updatedCount = 0;
  for (final workout in workouts) {
    var changed = false;
    final newExercises = <ExerciseLog>[];
    for (final exercise in workout.exercises) {
      final catalogExercise =
          exercise.exerciseId == null ? null : byId[exercise.exerciseId];
      final resolved = resolveMuscleGroup(
        catalogExercise,
        exercise.muscleGroup,
      );
      if (resolved == exercise.muscleGroup) {
        newExercises.add(exercise);
        continue;
      }
      changed = true;
      newExercises.add(
        ExerciseLog(
          name: exercise.name,
          muscleGroup: resolved,
          sets: exercise.sets,
          isPr: exercise.isPr,
          exerciseId: exercise.exerciseId,
          notes: exercise.notes,
        ),
      );
    }
    if (changed) {
      await workoutRepo.update(uid, workout.id, {
        'exercises': newExercises.map((e) => e.toJson()).toList(),
      });
      updatedCount++;
    }
  }
  return updatedCount;
}
