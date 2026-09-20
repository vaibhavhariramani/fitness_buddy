import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/story.dart';
import '../../../models/workout_entry.dart';

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
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      );
}
