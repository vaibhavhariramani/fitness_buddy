import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_text_styles.dart';
import '../../../core/providers.dart';
import '../../../core/utils/streak.dart';
import '../../../models/meal_entry.dart';
import '../../../models/user_profile.dart';
import '../../../models/weight_entry.dart';
import '../../../models/workout_entry.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// A friend's shared progress as a real report — weight trend, today's
/// training, muscle-group volume, and today's meal photos (each gated by
/// that friend's own privacy toggles) — instead of a quick bottom-sheet list
/// of raw log rows.
class FriendProgressPage extends ConsumerWidget {
  final UserProfile friend;

  const FriendProgressPage({required this.friend, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final displayStreak = StreakCalculator.currentDisplayStreak(
      storedStreak: friend.streakCount,
      lastLogDate: friend.lastLogDate,
    );
    final privacy = friend.privacy;
    final nothingShared =
        !privacy.shareWeight &&
        !privacy.shareWorkouts &&
        !privacy.shareStreak &&
        !privacy.shareMeals;

    return Scaffold(
      appBar: AppBar(title: Text(friend.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  (friend.displayName.isNotEmpty ? friend.displayName[0] : '?')
                      .toUpperCase(),
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (privacy.shareStreak)
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: AppColors.achievement,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$displayStreak day${displayStreak == 1 ? '' : 's'} streak',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (nothingShared)
            const AppCard(
              child: EmptyState(
                icon: Icons.lock_outline,
                title: 'Kept private',
                message: 'This friend hasn\'t shared their progress yet.',
              ),
            ),
          if (privacy.shareWeight) ...[
            _WeightSection(friendUid: friend.uid),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (privacy.shareWorkouts) ...[
            _TrainingSection(friendUid: friend.uid),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (privacy.shareMeals) ...[
            _TodaysMealsSection(friendUid: friend.uid),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _WeightSection extends ConsumerWidget {
  final String friendUid;

  const _WeightSection({required this.friendUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<WeightEntry>>(
      stream: ref.read(weightRepoProvider).watchAll(friendUid),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? const <WeightEntry>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Body'),
            AppCard(
              accentColor: AppColors.recovery,
              child:
                  logs.isEmpty
                      ? Text(
                        'No weight logs shared yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                logs.first.weightKg.toStringAsFixed(1),
                                style: AppTextStyles.statLarge(
                                  scheme.onSurface,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.xxs,
                                  bottom: 4,
                                ),
                                child: Text(
                                  'kg',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (logs.length >= 2) ...[
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              height: 100,
                              child: _FriendWeightSparkline(
                                entries: logs.reversed.take(30).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
            ),
          ],
        );
      },
    );
  }
}

class _FriendWeightSparkline extends StatelessWidget {
  final List<WeightEntry> entries;

  const _FriendWeightSparkline({required this.entries});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].weightKg),
    ];
    final values = entries.map((e) => e.weightKg);
    final minY = values.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 0.5;

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
            color: AppColors.recovery,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.recovery.withValues(alpha: 0.18),
                  AppColors.recovery.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingSection extends ConsumerWidget {
  final String friendUid;

  const _TrainingSection({required this.friendUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<WorkoutEntry>>(
      stream: ref.read(workoutRepoProvider).watchAll(friendUid),
      builder: (context, snapshot) {
        final workouts = snapshot.data ?? const <WorkoutEntry>[];
        final today = _dateOnly(DateTime.now());
        final todays =
            workouts.where((w) => _dateOnly(w.date) == today).toList();

        var exerciseCount = 0;
        var setCount = 0;
        var prCount = 0;
        for (final w in todays) {
          exerciseCount += w.exercises.length;
          for (final e in w.exercises) {
            setCount += e.sets.length;
            if (e.isPr) prCount++;
          }
        }

        final volumeByGroup = <String, int>{};
        for (final w in workouts) {
          for (final e in w.exercises) {
            volumeByGroup[e.muscleGroup] =
                (volumeByGroup[e.muscleGroup] ?? 0) + e.sets.length;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: "Today's Training"),
            AppCard(
              accentColor: AppColors.workout,
              child:
                  todays.isEmpty
                      ? Text(
                        'No workout logged today.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                      : Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.workout.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.workout,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              '$exerciseCount exercises · $setCount sets'
                              '${prCount > 0 ? ' · $prCount PR${prCount > 1 ? 's' : ''}' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Training Volume (all-time)'),
            AppCard(
              child: SizedBox(
                height: 160,
                child:
                    volumeByGroup.isEmpty
                        ? Center(
                          child: Text(
                            'No workouts shared yet.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        )
                        : _FriendMuscleChart(volumeByGroup: volumeByGroup),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FriendMuscleChart extends StatelessWidget {
  final Map<String, int> volumeByGroup;

  const _FriendMuscleChart({required this.volumeByGroup});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = volumeByGroup.keys.toList();
    return BarChart(
      BarChartData(
        alignment:
            groups.length <= 3
                ? BarChartAlignment.spaceEvenly
                : BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    groups[i],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
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
                BarChartRodData(
                  toY: volumeByGroup[groups[i]]!.toDouble(),
                  color: scheme.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TodaysMealsSection extends ConsumerWidget {
  final String friendUid;

  const _TodaysMealsSection({required this.friendUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<MealEntry>>(
      stream: ref
          .read(mealRepoProvider)
          .watchForDate(friendUid, DateTime.now()),
      builder: (context, snapshot) {
        final meals = snapshot.data ?? const <MealEntry>[];
        final withPhotos = meals.where((m) => m.photoUrl != null).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: "Today's Meals"),
            if (withPhotos.isEmpty)
              AppCard(
                child: Text(
                  'No meal photos shared today.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: withPhotos.length,
                  separatorBuilder:
                      (context, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final meal = withPhotos[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: meal.photoUrl!,
                            width: 120,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, _) => Container(
                                  width: 120,
                                  height: 140,
                                  color: scheme.surfaceContainerHigh,
                                ),
                            errorWidget:
                                (context, _, __) => Container(
                                  width: 120,
                                  height: 140,
                                  color: scheme.surfaceContainerHigh,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                              child: Text(
                                meal.mealType.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
