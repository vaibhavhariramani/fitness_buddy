import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_buddy/core/utils/calculations.dart';
import 'package:fitness_buddy/core/utils/streak.dart';
import 'package:fitness_buddy/core/utils/pr.dart';
import 'package:fitness_buddy/core/utils/progression.dart';
import 'package:fitness_buddy/core/utils/weekly_schedule.dart';

void main() {
  group('FitnessCalculations', () {
    test('bmi and category', () {
      final bmi = FitnessCalculations.bmi(weightKg: 70, heightCm: 175);
      expect(bmi, closeTo(22.86, 0.01));
      expect(FitnessCalculations.bmiCategory(bmi), BmiCategory.normal);
    });

    test('tdee is higher for more active users', () {
      final sedentary = FitnessCalculations.tdee(
        weightKg: 70,
        heightCm: 175,
        age: 25,
        gender: Gender.male,
        activityLevel: ActivityLevel.sedentary,
      );
      final veryActive = FitnessCalculations.tdee(
        weightKg: 70,
        heightCm: 175,
        age: 25,
        gender: Gender.male,
        activityLevel: ActivityLevel.veryActive,
      );
      expect(veryActive, greaterThan(sedentary));
    });

    test('calorie targets order correctly around maintenance', () {
      final targets = FitnessCalculations.calorieTargets(2500);
      expect(targets.aggressiveDeficit, lessThan(targets.moderateDeficit));
      expect(targets.moderateDeficit, lessThan(targets.mildDeficit));
      expect(targets.mildDeficit, lessThan(targets.maintenance));
      expect(targets.maintenance, lessThan(targets.surplus));
    });
  });

  group('StreakCalculator', () {
    test('first ever log starts a streak of 1', () {
      final result = StreakCalculator.onActivityLogged(
        previousStreak: 0,
        previousLastLogDate: null,
        today: DateTime(2026, 1, 10),
      );
      expect(result.streakCount, 1);
    });

    test('logging the next consecutive day increments the streak', () {
      final result = StreakCalculator.onActivityLogged(
        previousStreak: 3,
        previousLastLogDate: DateTime(2026, 1, 9),
        today: DateTime(2026, 1, 10),
      );
      expect(result.streakCount, 4);
    });

    test('missing a day resets the streak to 1', () {
      final result = StreakCalculator.onActivityLogged(
        previousStreak: 5,
        previousLastLogDate: DateTime(2026, 1, 5),
        today: DateTime(2026, 1, 10),
      );
      expect(result.streakCount, 1);
    });

    test('logging again the same day does not change the streak', () {
      final result = StreakCalculator.onActivityLogged(
        previousStreak: 4,
        previousLastLogDate: DateTime(2026, 1, 10),
        today: DateTime(2026, 1, 10),
      );
      expect(result.streakCount, 4);
    });
  });

  group('PrCalculator', () {
    test('a heavier estimated 1RM is flagged as a PR', () {
      final result = PrCalculator.check(
        newSet: const SetResult(weightKg: 100, reps: 5),
        previousBestOneRepMax: 110,
        previousBestWeightKg: 95,
        previousBestReps: 8,
      );
      expect(result.isPr, isTrue);
    });

    test('a lighter estimated 1RM is not a PR', () {
      final result = PrCalculator.check(
        newSet: const SetResult(weightKg: 60, reps: 5),
        previousBestOneRepMax: 110,
        previousBestWeightKg: 95,
        previousBestReps: 8,
      );
      expect(result.isPr, isFalse);
      expect(result.estOneRepMax, 110);
    });

    test('the very first logged set is always a PR', () {
      final result = PrCalculator.check(
        newSet: const SetResult(weightKg: 40, reps: 10),
      );
      expect(result.isPr, isTrue);
    });
  });

  group('suggestNextSession', () {
    test('returns null with no previous sets', () {
      expect(suggestNextSession(previousSets: const []), isNull);
    });

    test(
      'suggests a weight increase when every set hit the top of the range',
      () {
        final result = suggestNextSession(
          previousSets: const [
            (reps: 12, weightKg: 60.0),
            (reps: 12, weightKg: 60.0),
            (reps: 13, weightKg: 60.0),
          ],
          targetRepsMin: 8,
          targetRepsMax: 12,
          weightIncrementKg: 2.5,
        );
        expect(result, isNotNull);
        expect(result!.suggestedWeightKg, 62.5);
        expect(result.suggestedReps, 8);
      },
    );

    test(
      'suggests one more rep at the same weight when in-range but not maxed',
      () {
        final result = suggestNextSession(
          previousSets: const [
            (reps: 9, weightKg: 60.0),
            (reps: 8, weightKg: 60.0),
            (reps: 10, weightKg: 60.0),
          ],
          targetRepsMin: 8,
          targetRepsMax: 12,
        );
        expect(result, isNotNull);
        expect(result!.suggestedWeightKg, 60.0);
        // Lowest set was 8 reps, so the suggestion is 9.
        expect(result.suggestedReps, 9);
      },
    );

    test('suggests repeating the weight when the rep target was missed', () {
      final result = suggestNextSession(
        previousSets: const [
          (reps: 5, weightKg: 60.0),
          (reps: 6, weightKg: 60.0),
        ],
        targetRepsMin: 8,
        targetRepsMax: 12,
      );
      expect(result, isNotNull);
      expect(result!.suggestedWeightKg, 60.0);
      expect(result.suggestedReps, 8);
    });
  });

  group('resolveDayPlan', () {
    test('falls back to the routine when there is no override for the day', () {
      final planId = resolveDayPlan(
        routine: {1: 'push-day', 2: null},
        overrides: {},
        isoWeekday: 1,
      );
      expect(planId, 'push-day');
    });

    test('an override takes precedence over the routine', () {
      final planId = resolveDayPlan(
        routine: {2: null},
        overrides: {2: 'pull-day'},
        isoWeekday: 2,
      );
      expect(planId, 'pull-day');
    });

    test('an explicit rest override beats a routine that trains that day', () {
      final planId = resolveDayPlan(
        routine: {3: 'leg-day'},
        overrides: {3: null},
        isoWeekday: 3,
      );
      expect(planId, isNull);
    });

    test('a day missing from both routine and overrides is rest', () {
      final planId = resolveDayPlan(
        routine: const {},
        overrides: const {},
        isoWeekday: 5,
      );
      expect(planId, isNull);
    });
  });

  group('mondayOfWeek', () {
    // Anchored on DateTime.now() rather than a hardcoded date, so the test
    // doesn't depend on knowing which weekday a specific calendar date
    // falls on.
    final today = DateTime.now();
    final actualMonday = today.subtract(Duration(days: today.weekday - 1));
    final expectedMonday = DateTime(
      actualMonday.year,
      actualMonday.month,
      actualMonday.day,
    );

    test('returns the same date-only value for a Monday', () {
      expect(mondayOfWeek(expectedMonday), expectedMonday);
    });

    test(
      'rolls back to Monday for any day this week, ignoring time-of-day',
      () {
        final midWeek = expectedMonday.add(
          const Duration(days: 3, hours: 14, minutes: 30),
        );
        expect(mondayOfWeek(midWeek), expectedMonday);
      },
    );

    test('rolls back to Monday for the following Sunday', () {
      final sunday = expectedMonday.add(const Duration(days: 6));
      expect(mondayOfWeek(sunday), expectedMonday);
    });
  });
}
