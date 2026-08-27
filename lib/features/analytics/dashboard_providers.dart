import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/personal_record.dart';
import '../../models/workout_entry.dart';
import '../tracking/weight/weight_tab.dart';
import '../tracking/workouts/workouts_tab.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _mondayOf(DateTime d) {
  final day = _dateOnly(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// This calendar week's meals (Monday..today+future), for the weekly
/// consistency row — `todaysMealsProvider` only covers today.
final weeklyMealsProvider = StreamProvider.autoDispose((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  final monday = _mondayOf(DateTime.now());
  final end = monday.add(const Duration(days: 7));
  return ref.watch(mealRepoProvider).watchRange(uid, monday, end);
});

class WeeklyDayStatus {
  final DateTime date;
  final bool isActive;
  final bool isFuture;
  final bool isToday;

  const WeeklyDayStatus({
    required this.date,
    required this.isActive,
    required this.isFuture,
    required this.isToday,
  });
}

/// Monday-through-Sunday consistency for this calendar week, derived purely
/// from existing weight/workout/meal logs (a day counts as "active" if any
/// of the three has an entry on it) — no separate "activity log" collection
/// needed.
final weeklyConsistencyProvider = Provider.autoDispose<List<WeeklyDayStatus>>((
  ref,
) {
  final weightLogs = ref.watch(weightLogsProvider).valueOrNull ?? const [];
  final workouts = ref.watch(workoutHistoryProvider).valueOrNull ?? const [];
  final meals = ref.watch(weeklyMealsProvider).valueOrNull ?? const [];

  final monday = _mondayOf(DateTime.now());
  final today = _dateOnly(DateTime.now());

  final activeDates = <DateTime>{
    for (final e in weightLogs) _dateOnly(e.date),
    for (final e in workouts) _dateOnly(e.date),
    for (final e in meals) _dateOnly(e.date),
  };

  return List.generate(7, (i) {
    final date = monday.add(Duration(days: i));
    return WeeklyDayStatus(
      date: date,
      isActive: activeDates.contains(date),
      isFuture: date.isAfter(today),
      isToday: date == today,
    );
  });
});

/// Any workout(s) logged today, combined into one summary — exercises,
/// total sets, and PRs earned today. Null when nothing's been logged yet.
class TodaysWorkoutSummary {
  final int exerciseCount;
  final int setCount;
  final int prCount;

  const TodaysWorkoutSummary({
    required this.exerciseCount,
    required this.setCount,
    required this.prCount,
  });
}

final todaysWorkoutSummaryProvider =
    Provider.autoDispose<TodaysWorkoutSummary?>((ref) {
      final workouts =
          ref.watch(workoutHistoryProvider).valueOrNull ??
          const <WorkoutEntry>[];
      final today = _dateOnly(DateTime.now());
      final todays = workouts.where((w) => _dateOnly(w.date) == today).toList();
      if (todays.isEmpty) return null;

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
      return TodaysWorkoutSummary(
        exerciseCount: exerciseCount,
        setCount: setCount,
        prCount: prCount,
      );
    });

/// Workouts + PRs logged within this calendar week, for the streak card.
class WeeklyTrainingStats {
  final int workoutCount;
  final int prCount;

  const WeeklyTrainingStats({
    required this.workoutCount,
    required this.prCount,
  });
}

final weeklyTrainingStatsProvider = Provider.autoDispose<WeeklyTrainingStats>((
  ref,
) {
  final workouts =
      ref.watch(workoutHistoryProvider).valueOrNull ?? const <WorkoutEntry>[];
  final monday = _mondayOf(DateTime.now());
  final thisWeek = workouts.where((w) => !_dateOnly(w.date).isBefore(monday));

  var prCount = 0;
  for (final w in thisWeek) {
    for (final e in w.exercises) {
      if (e.isPr) prCount++;
    }
  }
  return WeeklyTrainingStats(workoutCount: thisWeek.length, prCount: prCount);
});

/// The most recently-achieved personal records, newest first, for the
/// dashboard's PR highlights row.
final recentPersonalRecordsProvider =
    StreamProvider.autoDispose<List<PersonalRecord>>((ref) {
      final uid = ref.watch(authStateProvider).valueOrNull?.uid;
      if (uid == null) return Stream.value(const []);
      return ref
          .watch(workoutRepoProvider)
          .watchPersonalRecords(uid)
          .map(
            (list) =>
                (List.of(list)
                  ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt))),
          );
    });
