import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_text_styles.dart';
import '../../../../core/utils/pr.dart';
import '../../../../models/workout_entry.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/muscle_body_diagram.dart';
import '../../../exercises/providers/exercise_providers.dart';
import '../../../exercises/widgets/add_to_workout_dialog.dart'
    show resolveMuscleGroup;
import 'workout_share_page.dart';

class WorkoutSummaryPage extends ConsumerWidget {
  final WorkoutEntry entry;
  final Duration? duration;

  const WorkoutSummaryPage({super.key, required this.entry, this.duration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final totalSets = entry.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );
    final totalVolume = entry.exercises.fold<double>(
      0,
      (sum, e) =>
          sum + e.sets.fold<double>(0, (s, set) => s + set.weightKg * set.reps),
    );
    final prExercises = entry.exercises.where((e) => e.isPr).toList();

    final setsByGroup = <String, int>{};
    for (final e in entry.exercises) {
      final catalogExercise =
          e.exerciseId == null
              ? null
              : ref.watch(exerciseByIdProvider(e.exerciseId!));
      final group = resolveMuscleGroup(catalogExercise, e.muscleGroup);
      setsByGroup[group] = (setsByGroup[group] ?? 0) + e.sets.length;
    }

    // "Best performance" — the heaviest estimated-1RM set across the
    // session, a simple, honest way to pick one highlight without needing
    // extra PR bookkeeping beyond what's already logged.
    ExerciseLog? bestExercise;
    ExerciseSet? bestSet;
    double bestEst1Rm = 0;
    for (final e in entry.exercises) {
      for (final s in e.sets) {
        final est =
            SetResult(weightKg: s.weightKg, reps: s.reps).estimatedOneRepMax;
        if (est > bestEst1Rm) {
          bestEst1Rm = est;
          bestExercise = e;
          bestSet = s;
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.md),
            Icon(
              prExercises.isNotEmpty
                  ? Icons.emoji_events_rounded
                  : Icons.check_circle_rounded,
              size: 56,
              color:
                  prExercises.isNotEmpty
                      ? AppColors.achievement
                      : AppColors.workout,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Workout Complete',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: 'Duration',
                      value:
                          duration == null ? '—' : _formatDuration(duration!),
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(label: 'Sets', value: '$totalSets'),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: 'Volume',
                      value: '${totalVolume.toStringAsFixed(0)} kg',
                    ),
                  ),
                ],
              ),
            ),
            if (prExercises.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                accentColor: AppColors.achievement,
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.achievement,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${prExercises.length} new PR${prExercises.length > 1 ? 's' : ''}: '
                        '${prExercises.map((e) => e.name).join(', ')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (bestExercise != null && bestSet != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Best performance',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            bestExercise.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${bestSet.weightKg.toStringAsFixed(0)}kg × ${bestSet.reps}',
                      style: AppTextStyles.statSmall(scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
            if (setsByGroup.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MuscleBodyDiagram(trainedSets: setsByGroup, height: 140),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final entry in setsByGroup.entries)
                            Chip(
                              label: Text('${entry.key} · ${entry.value}'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (entry.exercises.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercises', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    for (final e in entry.exercises)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              e.isPr
                                  ? Icons.emoji_events_rounded
                                  : Icons.check_circle_outline,
                              size: 18,
                              color:
                                  e.isPr
                                      ? AppColors.achievement
                                      : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _ReportBox(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.name,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ),
                                    if (e.isPr)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: AppSpacing.xs,
                                        ),
                                        child: Text(
                                          'PR',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall?.copyWith(
                                            color: AppColors.achievement,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _ReportBox(
                              child: Text(
                                e.setSummary,
                                style: AppTextStyles.statSmall(
                                  scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutSharePage(entry: entry),
                    ),
                  ),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share workout'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed:
                  () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    if (minutes < 1) return '<1 min';
    return '$minutes min';
  }
}

/// A small bordered surface for the report's "boxed" stat pairs (exercise
/// name, set summary) — distinct from [AppCard], which is the full-width
/// section container these boxes sit inside.
class _ReportBox extends StatelessWidget {
  final Widget child;

  const _ReportBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.compactRadius,
      ),
      child: child,
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value, style: AppTextStyles.statSmall(scheme.onSurface)),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
