import '../../models/user_profile.dart';
import 'calculations.dart';

class DailyNutritionTargets {
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;

  const DailyNutritionTargets({
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });
}

/// The single source of truth for "what are this user's daily nutrition
/// targets right now" — used by both the Diet Plan screen and the nutrition
/// dashboard so they can never disagree.
DailyNutritionTargets dailyNutritionTargets(UserProfile profile) {
  if (profile.nutritionGoal == NutritionGoal.custom &&
      profile.customCalorieTarget != null) {
    final calories = profile.customCalorieTarget!;
    final fallback = FitnessCalculations.macros(
      calorieTarget: calories,
      weightKg: profile.currentWeightKg,
    );
    return DailyNutritionTargets(
      calories: calories,
      proteinG: profile.customProteinG ?? fallback.proteinG,
      carbG: profile.customCarbG ?? fallback.carbG,
      fatG: profile.customFatG ?? fallback.fatG,
    );
  }

  final calories = profile.nutritionGoal.calorieTarget(profile.calorieTargets);
  final macros = FitnessCalculations.macros(
    calorieTarget: calories,
    weightKg: profile.currentWeightKg,
  );
  return DailyNutritionTargets(
    calories: calories,
    proteinG: macros.proteinG,
    carbG: macros.carbG,
    fatG: macros.fatG,
  );
}
