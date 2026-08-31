import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/providers.dart';
import '../../../../models/workout_plan.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../tracking/workouts/pages/active_workout_page.dart';
import '../workout_editor/workout_plans_tab.dart' show workoutPlansProvider;
import 'plan_picker.dart';
import 'weekly_plan_providers.dart';
import 'weekly_routine_editor_screen.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class WeeklyPlanTab extends ConsumerWidget {
  const WeeklyPlanTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedWeek = ref.watch(resolvedWeekProvider);
    final customPlans =
        ref.watch(workoutPlansProvider).valueOrNull ?? const <WorkoutPlan>[];
    final allPlans = ref.watch(availableWorkoutPlansProvider);
    final plansById = {for (final p in allPlans) p.id: p};
    final today = _dateOnly(DateTime.now());

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This Week', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeeklyRoutineEditorScreen(),
                      ),
                    ),
                icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                label: const Text('Edit routine'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final day in resolvedWeek)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _DayCard(
                day: day,
                plan: day.planId == null ? null : plansById[day.planId],
                isToday: _dateOnly(day.date) == today,
                customPlans: customPlans,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  final ResolvedDay day;
  final WorkoutPlan? plan;
  final bool isToday;
  final List<WorkoutPlan> customPlans;

  const _DayCard({
    required this.day,
    required this.plan,
    required this.isToday,
    required this.customPlans,
  });

  Future<void> _openOptions(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final weekStart = ref.read(weekStartProvider);
    final repo = ref.read(weekScheduleRepoProvider);

    final choice = await showModalBottomSheet<_DayAction>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.fitness_center_outlined),
                  title: const Text('Set workout for this week'),
                  onTap: () => Navigator.pop(context, _DayAction.setPlan),
                ),
                ListTile(
                  leading: const Icon(Icons.hotel_outlined),
                  title: const Text('Mark as rest (this week only)'),
                  onTap: () => Navigator.pop(context, _DayAction.rest),
                ),
                if (day.isOverridden)
                  ListTile(
                    leading: const Icon(Icons.replay_outlined),
                    title: const Text('Reset to routine'),
                    onTap: () => Navigator.pop(context, _DayAction.reset),
                  ),
              ],
            ),
          ),
    );
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case _DayAction.rest:
        await repo.setOverride(uid, weekStart, day.isoWeekday, null);
      case _DayAction.reset:
        await repo.clearOverride(uid, weekStart, day.isoWeekday);
      case _DayAction.setPlan:
        final picked = await _pickPlan(context, customPlans);
        if (picked != null) {
          await repo.setOverride(uid, weekStart, day.isoWeekday, picked.id);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      accentColor: isToday ? AppColors.workout : null,
      onTap: () => _openOptions(context, ref),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  _dayNames[day.isoWeekday - 1],
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.w700 : null,
                  ),
                ),
                Text(
                  DateFormat.d().format(day.date),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan?.name ?? 'Rest',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: plan == null ? scheme.onSurfaceVariant : null,
                  ),
                ),
                if (plan != null)
                  Text(
                    '${plan!.exercises.length} exercises · ~${plan!.estimatedMinutes} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (day.isOverridden)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Changed this week',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.achievement,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isToday && plan != null)
            FilledButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ActiveWorkoutPage(
                            title: plan!.name,
                            seeds: [
                              for (final p in plan!.exercises)
                                SessionExerciseSeed(
                                  exerciseId: p.exerciseId,
                                  exerciseName: p.exerciseName,
                                  targetSets: p.sets,
                                  targetReps: p.targetReps,
                                  isTimed: p.isTimed,
                                  restSeconds: p.restSeconds,
                                ),
                            ],
                          ),
                    ),
                  ),
              child: const Text('Start'),
            )
          else
            const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

enum _DayAction { setPlan, rest, reset }

Future<WorkoutPlan?> _pickPlan(
  BuildContext context,
  List<WorkoutPlan> customPlans,
) {
  return showModalBottomSheet<WorkoutPlan>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Choose a workout'),
                ),
                Flexible(
                  child: PlanOptionsList(
                    customPlans: customPlans,
                    samplePlans: sampleWorkoutPlansAsPlans,
                    onSelected: (p) => Navigator.pop(context, p),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}
