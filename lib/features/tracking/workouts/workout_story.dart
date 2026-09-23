import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/story.dart';
import '../../../models/workout_entry.dart';
import '../../exercises/providers/exercise_providers.dart';
import '../../exercises/widgets/add_to_workout_dialog.dart'
    show resolveMuscleGroup;

/// Posts a story for a just-finished workout — friends see what was
/// trained even without a photo — uploading [photoBytes] and attaching it
/// to both the story and the saved workout doc when provided.
///
/// Best-effort by design: callers should swallow failures here (wrap in a
/// try/catch that ignores the error) since the workout itself is already
/// saved by the time this runs, and a failed photo upload/story post
/// shouldn't be treated as a failed log.
Future<void> postWorkoutStory({
  required WidgetRef ref,
  required String uid,
  required WorkoutEntry saved,
  required Uint8List? photoBytes,
}) async {
  String? photoUrl;
  if (photoBytes != null) {
    photoUrl = await ref
        .read(storageServiceProvider)
        .uploadWorkoutPhoto(uid: uid, workoutId: saved.id, bytes: photoBytes);
    await ref.read(workoutRepoProvider).update(uid, saved.id, {
      'photoUrl': photoUrl,
    });
  }

  final setCount = saved.exercises.fold<int>(0, (n, e) => n + e.sets.length);
  final anyPr = saved.exercises.any((e) => e.isPr);

  // Same aggregation as the dashboard's weekly diagram and the external
  // share card, just scoped to this one workout — so the story's muscle
  // report matches what "Muscle Reports" would show for this session alone.
  final setsByGroup = <String, int>{};
  for (final e in saved.exercises) {
    final catalogExercise =
        e.exerciseId == null
            ? null
            : ref.read(exerciseByIdProvider(e.exerciseId!));
    final group = resolveMuscleGroup(catalogExercise, e.muscleGroup);
    setsByGroup[group] = (setsByGroup[group] ?? 0) + e.sets.length;
  }

  final now = DateTime.now();
  await ref
      .read(storyRepoProvider)
      .add(
        uid,
        Story(
          id: '',
          type: StoryType.workout,
          photoUrl: photoUrl,
          workoutExerciseCount: saved.exercises.length,
          workoutSetCount: setCount,
          workoutHasPr: anyPr,
          workoutSetsByGroup: setsByGroup,
          workoutExerciseNames: saved.exercises.map((e) => e.name).toList(),
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      );
}
