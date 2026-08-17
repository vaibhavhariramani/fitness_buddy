import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/muscle_group_images.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_providers.dart';
import '../../widgets/add_to_workout_dialog.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/exercise_substitute_sheet.dart';
import '../../widgets/exercise_visual.dart';
import '../../widgets/muscle_chip.dart';
import '../../widgets/muscle_group_image.dart';

/// A single scrollable page (not tabs — everything is visible by scrolling
/// so nothing gets missed): photo/pose art, then the muscle diagram, then
/// the complete preparation/execution instructions, then coaching notes.
class ExerciseDetailsScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const ExerciseDetailsScreen({super.key, required this.exerciseId});

  @override
  ConsumerState<ExerciseDetailsScreen> createState() =>
      _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends ConsumerState<ExerciseDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentlyViewedProvider.notifier).recordView(widget.exerciseId);
    });
  }

  Future<void> _replace(Exercise exercise) async {
    final substitute = await showExerciseSubstituteSheet(context, exercise);
    if (substitute != null && mounted) {
      context.pushReplacement('/exercises/${substitute.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(exerciseListProvider);
    final exercise = ref.watch(exerciseByIdProvider(widget.exerciseId));

    if (exercise == null) {
      if (listAsync.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Exercise not found.')),
      );
    }

    final hasMuscleDiagram = muscleGroupImageUrls.containsKey(
      exercise.category,
    );
    final hasCoachContent =
        exercise.formTips.isNotEmpty ||
        exercise.commonMistakes.isNotEmpty ||
        exercise.safetyNotes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        children: [
          // 1. Photo (or pose pictogram fallback) on top.
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Hero(
              tag: 'exercise-visual-${exercise.id}',
              child: ExerciseVisual(
                exerciseId: exercise.id,
                category: exercise.category,
                photoUrl: exercise.wgerImageUrl,
                iconSize: 56,
              ),
            ),
          ),
          if (exercise.wgerImageUrl == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                "No photo available for this exercise yet — showing a simple illustration instead.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'Photo: wger.de contributors • CC BY-SA 4.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MuscleChip(label: exercise.primaryMuscleNames, isPrimary: true),
                DifficultyBadge(difficulty: exercise.difficulty),
                for (final e in exercise.equipment) MuscleChip(label: e),
              ],
            ),
          ),

          // 2. Muscle group diagram.
          if (hasMuscleDiagram) ...[
            const SizedBox(height: 20),
            Center(child: MuscleGroupImage(category: exercise.category)),
            Center(
              child: Text(
                'Illustration: wger.de, CC BY-SA 4.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
          if (exercise.secondaryMuscles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secondary muscles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in exercise.secondaryMuscles)
                        MuscleChip(label: m),
                    ],
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Calories/set (est.)',
                    value: '~${exercise.calorieEstimatePerSet} kcal',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Avg. time/set (est.)',
                    value: '~${exercise.avgSecondsPerSet}s',
                  ),
                ),
              ],
            ),
          ),

          // 3. Complete instructions.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preparation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(exercise.preparation),
                const SizedBox(height: 20),
                Text(
                  'Execution',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(exercise.execution),
              ],
            ),
          ),

          // 4. Coaching notes.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coach', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (!hasCoachContent)
                  Text(
                    "Coaching notes aren't available for this exercise yet.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  )
                else ...[
                  if (exercise.formTips.isNotEmpty)
                    _CoachSection(
                      title: 'Form tips',
                      icon: Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      items: exercise.formTips,
                    ),
                  if (exercise.commonMistakes.isNotEmpty)
                    _CoachSection(
                      title: 'Common mistakes',
                      icon: Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      items: exercise.commonMistakes,
                    ),
                  if (exercise.safetyNotes.isNotEmpty)
                    _CoachSection(
                      title: 'Safety',
                      icon: Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                      items: exercise.safetyNotes,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Replace'),
                  onPressed: () => _replace(exercise),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add To Workout'),
                  onPressed:
                      () => showAddToWorkoutDialog(context, ref, exercise),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CoachSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _CoachSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
