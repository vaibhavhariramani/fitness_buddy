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
