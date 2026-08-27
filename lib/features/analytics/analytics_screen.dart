import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/providers.dart';
import '../../core/utils/streak.dart';
import '../../models/personal_record.dart';
import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';
import '../../models/workout_entry.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../nutrition/providers/nutrition_providers.dart';
import '../tracking/weight/weight_tab.dart';
import '../tracking/workouts/pages/active_workout_page.dart';
import '../tracking/workouts/workouts_tab.dart';
import 'dashboard_providers.dart';

/// The dashboard — the strongest screen in the app. Every section here reads
/// from data the app already tracks (nutrition, weight, workouts, PRs,
/// streak); nothing here is fabricated for visual effect.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final weightLogs =
        ref.watch(weightLogsProvider).valueOrNull ?? const <WeightEntry>[];
    final workouts =
        ref.watch(workoutHistoryProvider).valueOrNull ?? const <WorkoutEntry>[];

    if (profile == null) {
      return const Scaffold(body: _DashboardSkeleton());
    }

    final displayStreak = StreakCalculator.currentDisplayStreak(
      storedStreak: profile.streakCount,
      lastLogDate: profile.lastLogDate,
    );

    const stagger = Duration(milliseconds: 60);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.section,
          ),
          children: [
            _Header(profile: profile, streak: displayStreak),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(child: _TodayNutritionSection()),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(delay: stagger, child: const _TodayWorkoutSection()),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: stagger * 2,
              child: const _WeeklyConsistencySection(),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: stagger * 3,
              child: _BodySection(profile: profile, weightLogs: weightLogs),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: stagger * 4,
              child: _StreakSection(streak: displayStreak),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: stagger * 5,
              child: const _PrHighlightsSection(),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: stagger * 6,
              child: _MuscleVolumeSection(workouts: workouts),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: scheme.surfaceContainerHigh,
        highlightColor: scheme.surfaceContainerHighest,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              height: 28,
              width: 200,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final UserProfile profile;
  final int streak;

  const _Header({required this.profile, required this.streak});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _subtitle() {
    if (streak >= 3) return "You're on a $streak-day streak — keep it up.";
    if (streak == 1) return 'Nice start today. Keep the momentum going.';
    return "Let's make today count.";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final firstName =
        profile.displayName.trim().isEmpty
            ? null
            : profile.displayName.trim().split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName == null ? _greeting() : '${_greeting()}, $firstName',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _subtitle(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            backgroundImage:
                profile.photoUrl != null
                    ? NetworkImage(profile.photoUrl!)
                    : null,
            child:
                profile.photoUrl == null
                    ? Text(
                      (profile.displayName.isNotEmpty
                              ? profile.displayName[0]
                              : '?')
                          .toUpperCase(),
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                    : null,
          ),
        ),
      ],
    );
  }
}

class _TodayNutritionSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(todaysNutritionTotalsProvider);
    final targets = ref.watch(activeNutritionTargetsProvider);
    final scheme = Theme.of(context).colorScheme;

    final calorieTarget = targets?.calories ?? 0;
    final calorieProgress =
        calorieTarget <= 0
            ? 0.0
            : (totals.calories / calorieTarget).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Today'),
        AppCard(
          accentColor: AppColors.nutrition,
          child: Row(
            children: [
              ProgressRing(
                progress: calorieProgress,
                size: 92,
                strokeWidth: 9,
                color: AppColors.nutrition,
                trackColor: scheme.surfaceContainerHighest,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totals.calories.toStringAsFixed(0),
                      style: AppTextStyles.statSmall(scheme.onSurface),
                    ),
                    Text('kcal', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      targets == null
                          ? '${totals.calories.toStringAsFixed(0)} kcal logged'
                          : '${totals.calories.toStringAsFixed(0)} / ${targets.calories.toStringAsFixed(0)} kcal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MacroRow(
                      label: 'Protein',
                      grams: totals.proteinG,
                      targetGrams: targets?.proteinG,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    _MacroRow(
                      label: 'Carbs',
                      grams: totals.carbG,
                      targetGrams: targets?.carbG,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    _MacroRow(
                      label: 'Fat',
                      grams: totals.fatG,
                      targetGrams: targets?.fatG,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double grams;
  final double? targetGrams;

  const _MacroRow({required this.label, required this.grams, this.targetGrams});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value =
        targetGrams == null
            ? '${grams.toStringAsFixed(0)}g'
            : '${grams.toStringAsFixed(0)} / ${targetGrams!.toStringAsFixed(0)}g';
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value:
                  targetGrams == null || targetGrams == 0
                      ? 0
                      : (grams / targetGrams!).clamp(0, 1),
              minHeight: 5,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(AppColors.nutrition),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _TodayWorkoutSection extends ConsumerWidget {
  const _TodayWorkoutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaysWorkoutSummaryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Today's Training"),
        AppCard(
          accentColor: AppColors.workout,
          child:
              summary == null
                  ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No workout logged yet',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              "Start today's session when you're ready.",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const ActiveWorkoutPage(
                                      title: 'Workout',
                                    ),
                              ),
                            ),
                        child: const Text('Start'),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trained today',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              '${summary.exerciseCount} exercises · ${summary.setCount} sets'
                              '${summary.prCount > 0 ? ' · ${summary.prCount} PR${summary.prCount > 1 ? 's' : ''}' : ''}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}

class _WeeklyConsistencySection extends ConsumerWidget {
  const _WeeklyConsistencySection();

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(weeklyConsistencyProvider);
    final scheme = Theme.of(context).colorScheme;
    final activeCount = days.where((d) => d.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'This Week'),
        AppCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Column(
                      children: [
                        Text(
                          _labels[i],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _ConsistencyDot(status: days[i]),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$activeCount / 7 active days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsistencyDot extends StatelessWidget {
  final WeeklyDayStatus status;

  const _ConsistencyDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (status.isFuture) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder:
          (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              status.isActive
                  ? (status.isToday ? scheme.primary : AppColors.workout)
                  : scheme.surfaceContainerHighest,
          border:
              status.isToday && !status.isActive
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : null,
        ),
      ),
    );
  }
}

class _BodySection extends StatefulWidget {
  final UserProfile profile;
  final List<WeightEntry> weightLogs;

  const _BodySection({required this.profile, required this.weightLogs});

  @override
  State<_BodySection> createState() => _BodySectionState();
}

class _BodySectionState extends State<_BodySection> {
  int _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // weightLogs is newest-first (see WeightRepo.watchAll).
    final chronological = widget.weightLogs.reversed.toList();
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    final visible = chronological.where((e) => e.date.isAfter(cutoff)).toList();

    double? trendDelta;
    if (visible.length >= 2) {
      trendDelta = visible.last.weightKg - visible.first.weightKg;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Body'),
        AppCard(
          accentColor: AppColors.recovery,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.profile.currentWeightKg.toStringAsFixed(1),
                    style: AppTextStyles.statLarge(scheme.onSurface),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.xxs,
                      bottom: 4,
                    ),
                    child: Text(
                      'kg',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _RangeSelector(
                    selected: _rangeDays,
                    onChanged: (v) => setState(() => _rangeDays = v),
                  ),
                ],
              ),
              if (trendDelta != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    '${trendDelta >= 0 ? '↑' : '↓'} ${trendDelta.abs().toStringAsFixed(1)} kg over $_rangeDays days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 120,
                child:
                    visible.length < 2
                        ? Center(
                          child: Text(
                            'Log a few more entries to see a trend.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        )
                        : _WeightSparkline(entries: visible),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  static const _options = {7: '7D', 30: '30D', 90: '90D', 365: '1Y'};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in _options.entries)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs),
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      selected == entry.key
                          ? scheme.primaryContainer
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.value,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        selected == entry.key
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeightSparkline extends StatelessWidget {
  final List<WeightEntry> entries;

  const _WeightSparkline({required this.entries});

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

class _StreakSection extends ConsumerWidget {
  final int streak;

  const _StreakSection({required this.streak});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyTrainingStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Consistency'),
        AppCard(
          accentColor: AppColors.achievement,
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.achievement,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak day${streak == 1 ? '' : 's'} streak',
                      style: AppTextStyles.statMedium(scheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'This week: ${stats.workoutCount} workout${stats.workoutCount == 1 ? '' : 's'}'
                      '${stats.prCount > 0 ? ' · ${stats.prCount} PR${stats.prCount > 1 ? 's' : ''}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrHighlightsSection extends ConsumerWidget {
  const _PrHighlightsSection();

  static String _relative(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${(days / 7).floor()}w ago';
    return '${(days / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prs =
        ref.watch(recentPersonalRecordsProvider).valueOrNull ??
        const <PersonalRecord>[];
    final top = prs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Personal Records'),
        if (top.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No records yet',
              message: 'Log a workout to start tracking personal records.',
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < top.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _PrRow(pr: top[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _PrRow extends StatelessWidget {
  final PersonalRecord pr;

  const _PrRow({required this.pr});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.achievement.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.achievement,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pr.exerciseName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${pr.bestWeightKg.toStringAsFixed(0)} kg × ${pr.bestReps} · ${_PrHighlightsSection._relative(pr.achievedAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(
          '${pr.bestWeightKg.toStringAsFixed(0)}kg',
          style: AppTextStyles.statSmall(scheme.onSurface),
        ),
      ],
    );
  }
}

class _MuscleVolumeSection extends StatelessWidget {
  final List<WorkoutEntry> workouts;

  const _MuscleVolumeSection({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final volumeByGroup = <String, int>{};
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        volumeByGroup[exercise.muscleGroup] =
            (volumeByGroup[exercise.muscleGroup] ?? 0) + exercise.sets.length;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Training Volume (all-time)'),
        AppCard(
          child: SizedBox(
            height: 180,
            child:
                volumeByGroup.isEmpty
                    ? Center(
                      child: Text(
                        'Log a workout to see muscle group volume.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                    : _MuscleGroupChart(volumeByGroup: volumeByGroup),
          ),
        ),
      ],
    );
  }
}

class _MuscleGroupChart extends StatelessWidget {
  final Map<String, int> volumeByGroup;

  const _MuscleGroupChart({required this.volumeByGroup});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = volumeByGroup.keys.toList();
    return BarChart(
      BarChartData(
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
