import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/utils/exercise_history.dart';
import '../../data/muscle_group_images.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_providers.dart';
import '../../widgets/add_to_workout_dialog.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/exercise_substitute_sheet.dart';
import '../../widgets/exercise_visual.dart';
import '../../widgets/muscle_chip.dart';
import '../../widgets/muscle_group_image.dart';
import 'exercise_history_provider.dart';

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
    final history = ref.watch(exerciseHistoryProvider(widget.exerciseId));

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
                photoUrl: exercise.photoUrl,
                iconSize: 56,
              ),
            ),
          ),
          if (exercise.photoUrl == null)
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
                'Photo: free-exercise-db contributors • public domain',
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

          // 2b. Your history — only shows once this exercise has been
          // logged via the catalog (exerciseId-linked), so free-typed
          // workout entries don't silently appear here.
          if (history.isNotEmpty) _HistorySection(history: history),

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

class _HistorySection extends StatelessWidget {
  final List<ExerciseHistoryPoint> history;

  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = history.first;
    final best = history.reduce(
      (a, b) => b.estimatedOneRepMax > a.estimatedOneRepMax ? b : a,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your history', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Last session',
                  value:
                      '${last.bestWeightKg.toStringAsFixed(0)}kg × ${last.bestReps}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Best est. 1RM',
                  value: '${best.estimatedOneRepMax.toStringAsFixed(0)}kg',
                ),
              ),
            ],
          ),
          if (history.length > 1) ...[
            const SizedBox(height: 16),
            SizedBox(height: 80, child: _EstOneRepMaxChart(history: history)),
          ],
          const SizedBox(height: 12),
          for (final point in history.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd().format(point.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '${point.bestWeightKg.toStringAsFixed(0)}kg × ${point.bestReps}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EstOneRepMaxChart extends StatelessWidget {
  final List<ExerciseHistoryPoint> history;

  const _EstOneRepMaxChart({required this.history});

  @override
  Widget build(BuildContext context) {
    // history is most-recent-first; the chart reads left-to-right, oldest
    // first, so reverse it for plotting.
    final chronological = history.reversed.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < chronological.length; i++)
        FlSpot(i.toDouble(), chronological[i].estimatedOneRepMax),
    ];
    final values = chronological.map((p) => p.estimatedOneRepMax);
    final minY = values.reduce((a, b) => a < b ? a : b) - 2;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.achievement,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.achievement.withValues(alpha: 0.18),
                  AppColors.achievement.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
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
