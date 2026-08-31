import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercise.dart';
import '../providers/exercise_providers.dart';
import 'difficulty_badge.dart';
import 'exercise_visual.dart';

/// Shows the given exercise's curated substitutes and returns the one the
/// user picks, or null if dismissed.
Future<Exercise?> showExerciseSubstituteSheet(
  BuildContext context,
  Exercise exercise,
) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ExerciseSubstituteSheet(exercise: exercise),
  );
}

class _ExerciseSubstituteSheet extends ConsumerWidget {
  final Exercise exercise;

  const _ExerciseSubstituteSheet({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final substitutes =
        exercise.substitutes
            .map((id) => ref.watch(exerciseByIdProvider(id)))
            .whereType<Exercise>()
            .toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Replace ${exercise.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          if (substitutes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No substitutes suggested for this exercise yet.'),
            )
          else
            for (final sub in substitutes)
              ListTile(
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ExerciseVisual(
                      exerciseId: sub.id,
                      category: sub.category,
                      photoAsset: sub.photoAsset,
                      iconSize: 18,
                    ),
                  ),
                ),
                title: Text(sub.name),
                subtitle: Row(
                  children: [
                    Expanded(child: Text(sub.equipmentNames)),
                    DifficultyBadge(difficulty: sub.difficulty),
                  ],
                ),
                onTap: () => Navigator.pop(context, sub),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
