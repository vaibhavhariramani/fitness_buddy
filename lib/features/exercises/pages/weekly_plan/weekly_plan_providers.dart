import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/utils/weekly_schedule.dart';
import '../../../../models/week_schedule.dart';
import '../../../../models/weekly_routine.dart';

/// This calendar week's Monday — recomputed each time this provider is
/// (re)watched, so the planner naturally rolls to the new week without any
/// manual refresh logic.
final weekStartProvider = Provider.autoDispose<DateTime>(
  (ref) => mondayOfWeek(DateTime.now()),
);

final weeklyRoutineProvider = StreamProvider.autoDispose<WeeklyRoutine>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const WeeklyRoutine());
  return ref.watch(weeklyRoutineRepoProvider).watch(uid);
});

final thisWeekScheduleProvider = StreamProvider.autoDispose<WeekSchedule>((
  ref,
) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  final weekStart = ref.watch(weekStartProvider);
  if (uid == null) return Stream.value(WeekSchedule(weekStart: weekStart));
  return ref.watch(weekScheduleRepoProvider).watchWeek(uid, weekStart);
});

class ResolvedDay {
  final int isoWeekday;
  final DateTime date;

  /// WorkoutPlan id for this day, or null for rest.
  final String? planId;

  /// True when this week has an explicit override for this day (a
  /// reschedule/skip/swap), rather than just following the routine.
  final bool isOverridden;

  const ResolvedDay({
    required this.isoWeekday,
    required this.date,
    required this.planId,
    required this.isOverridden,
  });
}

/// The 7 resolved days (Monday..Sunday) for the current week — routine
/// defaults with this week's overrides applied on top. UI-friendly view over
/// the pure [resolveDayPlan] logic in core/utils/weekly_schedule.dart.
final resolvedWeekProvider = Provider.autoDispose<List<ResolvedDay>>((ref) {
  final routine =
      ref.watch(weeklyRoutineProvider).valueOrNull ?? const WeeklyRoutine();
  final schedule = ref.watch(thisWeekScheduleProvider).valueOrNull;
  final weekStart = ref.watch(weekStartProvider);
  final overrides = schedule?.overrides ?? const <int, String?>{};

  return List.generate(7, (i) {
    final weekday = i + 1;
    return ResolvedDay(
      isoWeekday: weekday,
      date: weekStart.add(Duration(days: i)),
      planId: resolveDayPlan(
        routine: routine.dayPlanIds,
        overrides: overrides,
        isoWeekday: weekday,
      ),
      isOverridden: overrides.containsKey(weekday),
    );
  });
});
