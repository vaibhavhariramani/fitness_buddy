import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_buddy/core/utils/calculations.dart';
import 'package:fitness_buddy/core/utils/streak.dart';
import 'package:fitness_buddy/core/utils/pr.dart';

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
}
