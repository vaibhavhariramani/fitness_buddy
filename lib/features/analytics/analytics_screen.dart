import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/streak.dart';
import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';
import '../../models/workout_entry.dart';
import '../nutrition/providers/nutrition_providers.dart';
import '../tracking/weight/weight_tab.dart';
import '../tracking/workouts/workouts_tab.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final weightLogs =
        ref.watch(weightLogsProvider).valueOrNull ?? const <WeightEntry>[];
    final meals = ref.watch(todaysMealsProvider).valueOrNull ?? const [];
    final workouts =
        ref.watch(workoutHistoryProvider).valueOrNull ?? const <WorkoutEntry>[];
    final personalRecords =
        ref.watch(_personalRecordsCountProvider).valueOrNull ?? 0;

    final displayStreak =
        profile == null
            ? 0
            : StreakCalculator.currentDisplayStreak(
              storedStreak: profile.streakCount,
              lastLogDate: profile.lastLogDate,
            );

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final columns = constraints.maxWidth < 420 ? 2 : 4;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _StatCard(
                    width: cardWidth,
                    icon: Icons.local_fire_department_outlined,
                    label: 'Day streak',
                    value: '$displayStreak',
                  ),
                  _StatCard(
                    width: cardWidth,
                    icon: Icons.monitor_weight_outlined,
                    label: 'Current weight',
                    value:
                        profile == null
                            ? '—'
                            : '${profile.currentWeightKg.toStringAsFixed(1)} kg',
                  ),
                  _StatCard(
                    width: cardWidth,
                    icon: Icons.flag_outlined,
                    label: 'Target weight',
                    value:
                        profile == null
                            ? '—'
                            : '${profile.targetWeightKg.toStringAsFixed(1)} kg',
                  ),
                  _StatCard(
                    width: cardWidth,
                    icon: Icons.emoji_events_outlined,
                    label: 'Personal records',
                    value: '$personalRecords',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Weight trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _WeightTrendChart(entries: weightLogs)),
          const SizedBox(height: 24),
          Text(
            'Muscle group volume (all-time sets)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _MuscleGroupChart(workouts: workouts)),
          const SizedBox(height: 24),
          if (profile != null)
            _WeeklySummary(profile: profile, weightLogs: weightLogs),
          const SizedBox(height: 8),
          Text(
            'Today: ${meals.length} meal(s) logged',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

final _personalRecordsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0);
  return ref
      .watch(workoutRepoProvider)
      .watchPersonalRecords(uid)
      .map((list) => list.length);
});

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightTrendChart extends StatelessWidget {
  final List<WeightEntry> entries;

  const _WeightTrendChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const Center(
        child: Text('Log more weight entries to see a trend.'),
      );
    }
    final chronological = entries.reversed.toList();
    final spots = <FlSpot>[
      for (var i = 0; i < chronological.length; i++)
        FlSpot(i.toDouble(), chronological[i].weightKg),
    ];
    return LineChart(
      LineChartData(
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupChart extends StatelessWidget {
  final List<WorkoutEntry> workouts;

  const _MuscleGroupChart({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final volumeByGroup = <String, int>{};
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        volumeByGroup[exercise.muscleGroup] =
            (volumeByGroup[exercise.muscleGroup] ?? 0) + exercise.sets.length;
      }
    }
    if (volumeByGroup.isEmpty) {
      return const Center(
        child: Text('Log a workout to see muscle group volume.'),
      );
    }
    final groups = volumeByGroup.keys.toList();
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= groups.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(groups[i], style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < groups.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: volumeByGroup[groups[i]]!.toDouble()),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  final UserProfile profile;
  final List<WeightEntry> weightLogs;

  const _WeeklySummary({required this.profile, required this.weightLogs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = weightLogs.where((e) => e.date.isAfter(weekAgo)).toList();
    final avg =
        recent.isEmpty
            ? null
            : recent.map((e) => e.weightKg).reduce((a, b) => a + b) /
                recent.length;

    String trend = 'stable';
    if (recent.length >= 2) {
      final first = recent.first.weightKg;
      final last = recent.last.weightKg;
      if ((last - first).abs() > 0.2) {
        final towardTarget =
            (last - first).sign == (profile.targetWeightKg - first).sign;
        trend =
            towardTarget
                ? 'trending toward target'
                : 'trending away from target';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              avg == null
                  ? 'Not enough data this week yet.'
                  : 'Average weight this week: ${avg.toStringAsFixed(1)} kg ($trend)',
            ),
          ],
        ),
      ),
    );
  }
}
