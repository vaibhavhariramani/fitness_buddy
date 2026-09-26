import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_text_styles.dart';
import '../../../../models/personal_record.dart';
import '../../../../models/workout_entry.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/muscle_body_diagram.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../analytics/dashboard_providers.dart';
import '../../../tracking/workouts/workouts_tab.dart';
import '../../data/muscle_group_images.dart';
import '../../providers/exercise_providers.dart';
import '../../widgets/add_to_workout_dialog.dart' show resolveMuscleGroup;
import '../../widgets/category_visual.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/muscle_group_image.dart';

class _MuscleStats {
  final String muscleGroup;
  int weeklySets = 0;
  int monthlySets = 0;
  int allTimeSets = 0;
  final Set<String> workoutDates = {};
  DateTime? lastTrained;

  _MuscleStats(this.muscleGroup);

  int? get daysSinceLastTrained {
    final last = lastTrained;
    if (last == null) return null;
    return DateTime.now().difference(last).inDays;
  }

  String get recoveryLabel {
    final days = daysSinceLastTrained;
    if (days == null) return 'Not trained yet';
    if (days < 2) return 'Recovering';
    if (days < 5) return 'Ready soon';
    return 'Ready to train';
  }
}

Map<String, _MuscleStats> _computeStats(
  WidgetRef ref,
  List<WorkoutEntry> workouts,
) {
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  final monthAgo = now.subtract(const Duration(days: 30));
  final stats = {for (final g in muscleGroups) g: _MuscleStats(g)};

  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      final catalogExercise =
          exercise.exerciseId == null
              ? null
              : ref.watch(exerciseByIdProvider(exercise.exerciseId!));
      final muscleGroup = resolveMuscleGroup(
        catalogExercise,
        exercise.muscleGroup,
      );
      final s = stats.putIfAbsent(muscleGroup, () => _MuscleStats(muscleGroup));
      s.allTimeSets += exercise.sets.length;
      s.workoutDates.add(
        '${workout.date.year}-${workout.date.month}-${workout.date.day}',
      );
      if (s.lastTrained == null || workout.date.isAfter(s.lastTrained!)) {
        s.lastTrained = workout.date;
      }
      if (workout.date.isAfter(weekAgo)) s.weeklySets += exercise.sets.length;
      if (workout.date.isAfter(monthAgo)) s.monthlySets += exercise.sets.length;
    }
  }
  return stats;
}

class MuscleReportsTab extends ConsumerWidget {
  const MuscleReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load: $e')),
      data: (workouts) {
        if (workouts.isEmpty) {
          return const EmptyState(
            icon: Icons.insights_outlined,
            title: 'No workouts logged yet',
            message:
                'Log a workout in Tracking to see your muscle group reports here.',
          );
        }
        final stats = _computeStats(ref, workouts);
        final ordered = muscleGroups.map((g) => stats[g]!).toList();
        final weeklySetsByGroup = {
          for (final s in ordered)
            if (s.weeklySets > 0) s.muscleGroup: s.weeklySets,
        };
        final totalWeeklySets = weeklySetsByGroup.values.fold(0, (a, b) => a + b);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _WeeklyHeroCard(
              weeklySetsByGroup: weeklySetsByGroup,
              totalWeeklySets: totalWeeklySets,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Personal Records'),
            const _PersonalRecordsSection(),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Weekly Volume'),
            AppCard(child: SizedBox(height: 180, child: _WeeklySetsChart(stats: ordered))),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Muscle Detail'),
            for (final s in ordered) _MuscleCard(stats: s),
          ],
        );
      },
    );
  }
}

/// This week's training at a glance — the body diagram plus a per-group
/// breakdown, styled as the report's hero so the most "premium"-feeling
/// visual (the diagram) is the first thing seen, matching the treatment the
/// dashboard's own "Muscles Trained This Week" widget already uses.
class _WeeklyHeroCard extends StatelessWidget {
  final Map<String, int> weeklySetsByGroup;
  final int totalWeeklySets;

  const _WeeklyHeroCard({
    required this.weeklySetsByGroup,
    required this.totalWeeklySets,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      accentColor: AppColors.workout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '$totalWeeklySets',
                style: AppTextStyles.statMedium(AppColors.workout),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'sets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (totalWeeklySets == 0)
            Text(
              'No sets logged this week yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MuscleBodyDiagram(trainedSets: weeklySetsByGroup, height: 160),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final entry in weeklySetsByGroup.entries)
                        Chip(
                          avatar: CircleAvatar(
                            backgroundColor: categoryColor(entry.key),
                            radius: 6,
                          ),
                          label: Text('${entry.key} · ${entry.value}'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The most recent personal records — reuses the same stream the dashboard's
/// PR highlights row is built from, so this report and the dashboard never
/// disagree about what counts as a PR.
class _PersonalRecordsSection extends ConsumerWidget {
  const _PersonalRecordsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final recordsAsync = ref.watch(recentPersonalRecordsProvider);
    return recordsAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (e, _) => const SizedBox.shrink(),
      data: (records) {
        if (records.isEmpty) {
          return AppCard(
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No PRs yet — keep training to set your first one.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final recent = records.take(6).toList();
        return AppCard(
          accentColor: AppColors.achievement,
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0) const Divider(height: AppSpacing.lg),
                _PersonalRecordRow(record: recent[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PersonalRecordRow extends StatelessWidget {
  final PersonalRecord record;

  const _PersonalRecordRow({required this.record});

  String _daysAgoLabel(DateTime achievedAt) {
    final days = DateTime.now().difference(achievedAt).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Icon(Icons.emoji_events_rounded, color: AppColors.achievement),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.exerciseName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                _daysAgoLabel(record.achievedAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(
          '${record.bestWeightKg.toStringAsFixed(0)}kg × ${record.bestReps}',
          style: AppTextStyles.statSmall(scheme.onSurface),
        ),
      ],
    );
  }
}

class _WeeklySetsChart extends StatelessWidget {
  final List<_MuscleStats> stats;

  const _WeeklySetsChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxY = stats.fold<int>(
      0,
      (m, s) => s.weeklySets > m ? s.weeklySets : m,
    );
    if (maxY == 0) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No sets this week',
        message: 'Log a workout to see this week\'s volume per muscle group.',
      );
    }
    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= stats.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    stats[i].muscleGroup,
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < stats.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stats[i].weeklySets.toDouble(),
                  color: categoryColor(stats[i].muscleGroup),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MuscleCard extends StatelessWidget {
  final _MuscleStats stats;

  const _MuscleCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        accentColor: categoryColor(stats.muscleGroup),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    muscleGroupImageUrls.containsKey(stats.muscleGroup)
                        ? MuscleGroupImage(
                          category: stats.muscleGroup,
                          height: 44,
                        )
                        : CategoryVisual(
                          category: stats.muscleGroup,
                          iconSize: 20,
                        ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.muscleGroup,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text('This week: ${stats.weeklySets} sets'),
                      Text('This month: ${stats.monthlySets} sets'),
                      Text('${stats.workoutDates.length} workout(s) all-time'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.lastTrained == null
                        ? 'Never trained'
                        : 'Last trained ${_daysAgoLabel(stats.daysSinceLastTrained!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Tooltip(
              message:
                  'A simple heuristic based on days since last trained — not a physiological measure',
              child: Chip(
                label: Text(stats.recoveryLabel),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _daysAgoLabel(int days) {
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}
