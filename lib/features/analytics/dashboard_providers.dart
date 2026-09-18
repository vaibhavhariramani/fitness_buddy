import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/calculations.dart';
import '../../models/meal_entry.dart';
import '../../models/personal_record.dart';
import '../../models/workout_entry.dart';
import '../exercises/providers/exercise_providers.dart';
import '../exercises/widgets/add_to_workout_dialog.dart' show resolveMuscleGroup;
import '../nutrition/data/common_foods.dart';
import '../nutrition/models/food.dart';
import '../nutrition/providers/nutrition_providers.dart';
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

/// Sets performed per muscle group within this calendar week (Monday..now),
/// for the "muscles trained this week" body diagram.
final weeklyMuscleGroupsProvider = Provider.autoDispose<Map<String, int>>((
  ref,
) {
  final workouts =
      ref.watch(workoutHistoryProvider).valueOrNull ?? const <WorkoutEntry>[];
  final monday = _mondayOf(DateTime.now());
  final thisWeek = workouts.where((w) => !_dateOnly(w.date).isBefore(monday));

  final setsByGroup = <String, int>{};
  for (final w in thisWeek) {
    for (final e in w.exercises) {
      final catalogExercise =
          e.exerciseId == null
              ? null
              : ref.watch(exerciseByIdProvider(e.exerciseId!));
      final group = resolveMuscleGroup(catalogExercise, e.muscleGroup);
      setsByGroup[group] = (setsByGroup[group] ?? 0) + e.sets.length;
    }
  }
  return setsByGroup;
});

/// Meals logged in the last 7 days (rolling, not calendar-week), for the
/// progress-suggestions heuristic below — a calendar-week window would be
/// too short on a Monday to say anything useful about eating patterns.
final _recentMealsProvider = StreamProvider.autoDispose((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  final now = DateTime.now();
  return ref
      .watch(mealRepoProvider)
      .watchRange(uid, now.subtract(const Duration(days: 7)), now);
});

/// A single data-driven nudge for the dashboard: "you're on track" when
/// weight is moving the right way for the user's goal, or a concrete
/// suggestion (call out the most-repeated food and roughly how much to trim
/// it) when it's stalled or moving the wrong way despite a calorie gap.
/// Null when there isn't enough logged history yet to say anything honest.
class ProgressSuggestion {
  final String title;
  final String message;
  final bool isPositive;

  const ProgressSuggestion({
    required this.title,
    required this.message,
    this.isPositive = false,
  });
}

final _gramsPattern = RegExp(r'(\d+(\.\d+)?)\s*g');

final progressSuggestionProvider = Provider.autoDispose<ProgressSuggestion?>((
  ref,
) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) return null;
  final goal = profile.nutritionGoal;
  // Nothing directional to say for maintain/custom — the weight-stable
  // signal is the point, not a problem to fix.
  if (goal != NutritionGoal.loseWeight &&
      goal != NutritionGoal.gainMuscle &&
      goal != NutritionGoal.recomp) {
    return null;
  }

  final weightLogs = ref.watch(weightLogsProvider).valueOrNull ?? const [];
  final windowStart = DateTime.now().subtract(const Duration(days: 14));
  final recentWeights =
      weightLogs.where((e) => e.date.isAfter(windowStart)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  if (recentWeights.length < 3) return null;
  final weightTrendKg = recentWeights.last.weightKg - recentWeights.first.weightKg;

  final meals = ref.watch(_recentMealsProvider).valueOrNull ?? const [];
  final caloriesByDay = <DateTime, double>{};
  for (final m in meals) {
    final day = _dateOnly(m.date);
    caloriesByDay[day] = (caloriesByDay[day] ?? 0) + m.calories;
  }
  // Fewer than 3 logged days can't support a daily-average claim.
  if (caloriesByDay.length < 3) return null;
  final avgDailyCalories =
      caloriesByDay.values.reduce((a, b) => a + b) / caloriesByDay.length;

  final target =
      goal == NutritionGoal.custom
          ? (profile.customCalorieTarget ?? profile.calorieTargets.maintenance)
          : goal.calorieTarget(profile.calorieTargets);

  const stallThresholdKg = 0.3;
  final wantsLoss = goal == NutritionGoal.loseWeight || goal == NutritionGoal.recomp;
  final wantsGain = goal == NutritionGoal.gainMuscle;
  final isStalledOrWrongWay =
      wantsLoss ? weightTrendKg > -stallThresholdKg : weightTrendKg < stallThresholdKg;

  if (isStalledOrWrongWay) {
    final overBy = avgDailyCalories - target;
    if (wantsLoss && overBy > 100) {
      return ProgressSuggestion(
        title: 'Try this next',
        message: _portionSuggestion(meals, avgDailyCalories, overBy) ??
            "You're averaging ${avgDailyCalories.round()} kcal/day, about "
                '${overBy.round()} kcal over your target for the last week — '
                'trimming portions slightly should help.',
      );
    }
    if (wantsGain && overBy < -100) {
      return ProgressSuggestion(
        title: 'Try this next',
        message:
            "You're averaging ${avgDailyCalories.round()} kcal/day, about "
            '${(-overBy).round()} kcal under your target — add a bit more at '
            'your next meal or a snack to support muscle gain.',
      );
    }
  } else {
    return ProgressSuggestion(
      title: "You're on track",
      message:
          'Weight has moved ${weightTrendKg.abs().toStringAsFixed(1)} kg '
          'toward your goal over the last 2 weeks — keep it up.',
      isPositive: true,
    );
  }

  return null;
});

/// Finds the most-repeated named food in [meals] and, when its logged
/// serving includes a gram amount, suggests a concrete trimmed portion
/// (mirroring how a person would reason about it) rather than a vague
/// percentage. Returns null when no named food repeats enough to single out.
String? _portionSuggestion(
  List<MealEntry> meals,
  double avgDailyCalories,
  double overBy,
) {
  final byName = <String, List<MealEntry>>{};
  for (final m in meals) {
    final name = m.foodName;
    if (name == null || name.trim().isEmpty || name == 'Photo') continue;
    byName.putIfAbsent(name, () => []).add(m);
  }
  if (byName.isEmpty) return null;

  final top = byName.entries.reduce(
    (a, b) => a.value.length >= b.value.length ? a : b,
  );
  if (top.value.length < 3) return null; // not a real repeated pattern yet

  final name = top.key;
  final instances = top.value;
  final avgCalPerInstance =
      instances.map((e) => e.calories).reduce((a, b) => a + b) /
      instances.length;

  final gramsMatch = _gramsPattern.firstMatch(
    instances.last.servingDescription ?? '',
  );
  final cutFraction = (overBy / avgDailyCalories).clamp(0.1, 0.5);
  final String portionAdvice;
  if (gramsMatch != null) {
    final grams = double.parse(gramsMatch.group(1)!);
    final suggestedGrams = ((grams * (1 - cutFraction)) / 10).round() * 10;
    portionAdvice = 'try trimming it to about ${suggestedGrams}g';
  } else {
    final pct = (cutFraction * 100).round();
    portionAdvice = 'try cutting the portion by about $pct%';
  }

  return "You've logged $name ${instances.length}x this week "
      '(~${avgCalPerInstance.round()} kcal each). '
      "You're averaging ${avgDailyCalories.round()} kcal/day, about "
      '${overBy.round()} over your target — $portionAdvice.';
}

/// A protein shortfall nudge, separate from [progressSuggestionProvider]
/// (which is calorie/goal-direction driven) — this fires purely on protein
/// intake vs. target, regardless of nutrition goal, since under-eating
/// protein matters whether you're cutting, bulking, or maintaining.
class ProteinInsight {
  final double avgDailyProteinG;
  final double targetProteinG;
  final List<String> suggestions;

  const ProteinInsight({
    required this.avgDailyProteinG,
    required this.targetProteinG,
    required this.suggestions,
  });
}

final proteinInsightProvider = Provider.autoDispose<ProteinInsight?>((ref) {
  final targets = ref.watch(activeNutritionTargetsProvider);
  if (targets == null || targets.proteinG <= 0) return null;

  final meals = ref.watch(_recentMealsProvider).valueOrNull ?? const [];
  final proteinByDay = <DateTime, double>{};
  for (final m in meals) {
    final day = _dateOnly(m.date);
    proteinByDay[day] = (proteinByDay[day] ?? 0) + m.proteinG;
  }
  // Fewer than 3 logged days can't support a daily-average claim.
  if (proteinByDay.length < 3) return null;

  final avgDailyProtein =
      proteinByDay.values.reduce((a, b) => a + b) / proteinByDay.length;
  // A little short is noise, not a pattern worth interrupting the dashboard
  // for — only flag a real, consistent shortfall.
  if (avgDailyProtein >= targets.proteinG * 0.85) return null;

  final topProteinFoods = List<Food>.from(commonFoods)
    ..sort((a, b) => b.proteinPer100g.compareTo(a.proteinPer100g));
  final suggestions = topProteinFoods.take(4).map((f) => f.name).toList();

  return ProteinInsight(
    avgDailyProteinG: avgDailyProtein,
    targetProteinG: targets.proteinG,
    suggestions: suggestions,
  );
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
