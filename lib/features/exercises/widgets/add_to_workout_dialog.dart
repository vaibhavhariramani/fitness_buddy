import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/tracking/workouts/workout_prefill_provider.dart';
import '../models/exercise.dart';

/// Maps this feature's exercise categories onto Tracking's existing
/// free-text muscle group vocabulary (see workouts_tab.dart's `muscleGroups`)
/// — identical for every category except Cardio, which Tracking has no
/// dedicated bucket for.
String nearestMuscleGroup(Exercise exercise) {
  if (exercise.category == 'Cardio') return 'Full body';
  return exercise.category;
}

/// The muscle group to show for a logged exercise — prefers a live catalog
/// lookup ([catalogExercise], resolved by the caller via
/// `exerciseByIdProvider(log.exerciseId)`) over whatever was stored on the
/// log at the time it was created, falling back to that stored value only
/// when the id doesn't resolve (a genuinely custom/free-typed exercise, or
/// one since removed from the catalog).
///
/// Historical logs baked in whatever the catalog said at logging time, so a
/// workout logged before an exercise's category was correctly populated
/// stays stuck showing that stale value (often a generic "Full body")
/// forever unless re-derived — this is what re-derives it, everywhere
/// muscle-group stats are aggregated for display.
String resolveMuscleGroup(Exercise? catalogExercise, String storedMuscleGroup) {
  return catalogExercise != null
      ? nearestMuscleGroup(catalogExercise)
      : storedMuscleGroup;
}

Future<void> showAddToWorkoutDialog(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise,
) {
  return showDialog<void>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Add to workout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.checklist_outlined),
                title: const Text('Log in Tracking'),
                subtitle: const Text('Opens the workout log, pre-filled'),
                onTap: () {
                  ref
                      .read(pendingWorkoutPrefillProvider.notifier)
                      .state = WorkoutPrefill(
                    name: exercise.name,
                    muscleGroup: nearestMuscleGroup(exercise),
                  );
                  Navigator.pop(context);
                  context.push('/tracking');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
  );
}
