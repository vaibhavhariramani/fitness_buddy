import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/workout_entry.dart';
import '../../../tracking/workouts/workouts_tab.dart';
import '../../data/muscle_group_images.dart';
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

Map<String, _MuscleStats> _computeStats(List<WorkoutEntry> workouts) {
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  final monthAgo = now.subtract(const Duration(days: 30));
  final stats = {for (final g in muscleGroups) g: _MuscleStats(g)};

  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      final s = stats.putIfAbsent(
        exercise.muscleGroup,
        () => _MuscleStats(exercise.muscleGroup),
      );
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
        final stats = _computeStats(workouts);
        final ordered = muscleGroups.map((g) => stats[g]!).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'This week, by muscle group',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(height: 180, child: _WeeklySetsChart(stats: ordered)),
            const SizedBox(height: 20),
            Text(
              'Muscle group detail',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final s in ordered) _MuscleCard(stats: s),
          ],
        );
      },
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
            const SizedBox(width: 12),
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
