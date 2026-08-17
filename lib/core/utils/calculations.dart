/// BMI, TDEE and macro-target calculations.
///
/// Formulas used:
/// - BMI: weightKg / (heightM^2)
/// - BMR: Mifflin-St Jeor equation
/// - TDEE: BMR * activity multiplier
library;

enum Gender { male, female }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

extension ActivityLevelMultiplier on ActivityLevel {
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.lightlyActive:
        return 1.375;
      case ActivityLevel.moderatelyActive:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
      case ActivityLevel.extraActive:
        return 1.9;
    }
  }

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary (little or no exercise)';
      case ActivityLevel.lightlyActive:
        return 'Lightly active (1-3 days/week)';
      case ActivityLevel.moderatelyActive:
        return 'Moderately active (3-5 days/week)';
      case ActivityLevel.veryActive:
        return 'Very active (6-7 days/week)';
      case ActivityLevel.extraActive:
        return 'Extra active (physical job + training)';
    }
  }
}

enum BmiCategory { underweight, normal, overweight, obese }

extension BmiCategoryLabel on BmiCategory {
  String get label {
    switch (this) {
      case BmiCategory.underweight:
        return 'Underweight';
      case BmiCategory.normal:
        return 'Normal';
      case BmiCategory.overweight:
        return 'Overweight';
      case BmiCategory.obese:
        return 'Obese';
    }
  }
}

class CalorieTargets {
  final double maintenance;
  final double mildDeficit;
  final double moderateDeficit;
  final double aggressiveDeficit;
  final double surplus;

  const CalorieTargets({
    required this.maintenance,
    required this.mildDeficit,
    required this.moderateDeficit,
    required this.aggressiveDeficit,
    required this.surplus,
  });

  Map<String, double> toJson() => {
    'maintenance': maintenance,
    'mildDeficit': mildDeficit,
    'moderateDeficit': moderateDeficit,
    'aggressiveDeficit': aggressiveDeficit,
    'surplus': surplus,
  };

  factory CalorieTargets.fromJson(Map<String, dynamic> json) => CalorieTargets(
    maintenance: (json['maintenance'] as num).toDouble(),
    mildDeficit: (json['mildDeficit'] as num).toDouble(),
    moderateDeficit: (json['moderateDeficit'] as num).toDouble(),
    aggressiveDeficit: (json['aggressiveDeficit'] as num).toDouble(),
    surplus: (json['surplus'] as num).toDouble(),
  );
}

class Macros {
  final double proteinG;
  final double fatG;
  final double carbG;

  const Macros({
    required this.proteinG,
    required this.fatG,
    required this.carbG,
  });

  Map<String, double> toJson() => {
    'proteinG': proteinG,
    'fatG': fatG,
    'carbG': carbG,
  };

  factory Macros.fromJson(Map<String, dynamic> json) => Macros(
    proteinG: (json['proteinG'] as num).toDouble(),
    fatG: (json['fatG'] as num).toDouble(),
    carbG: (json['carbG'] as num).toDouble(),
  );
}

enum NutritionGoal { loseWeight, maintain, gainMuscle, recomp, custom }

extension NutritionGoalLabel on NutritionGoal {
  String get label {
    switch (this) {
      case NutritionGoal.loseWeight:
        return 'Lose weight';
      case NutritionGoal.maintain:
        return 'Maintain';
      case NutritionGoal.gainMuscle:
        return 'Gain muscle';
      case NutritionGoal.recomp:
        return 'Recomposition';
      case NutritionGoal.custom:
        return 'Custom';
    }
  }
}

extension NutritionGoalCalories on NutritionGoal {
  /// Maps this goal onto one of the precomputed [CalorieTargets] fields.
  /// Unused for [NutritionGoal.custom] — that path is handled separately by
  /// callers using the profile's custom override fields.
  double calorieTarget(CalorieTargets targets) {
    switch (this) {
      case NutritionGoal.loseWeight:
        return targets.moderateDeficit;
      case NutritionGoal.maintain:
        return targets.maintenance;
      case NutritionGoal.gainMuscle:
        return targets.surplus;
      case NutritionGoal.recomp:
        return targets.mildDeficit;
      case NutritionGoal.custom:
        return targets.maintenance;
    }
  }
}

class FitnessCalculations {
  const FitnessCalculations._();

  static double bmi({required double weightKg, required double heightCm}) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static BmiCategory bmiCategory(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  /// Basal Metabolic Rate via Mifflin-St Jeor.
  static double bmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return gender == Gender.male ? base + 5 : base - 161;
  }

  static double tdee({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
    required ActivityLevel activityLevel,
  }) {
    return bmr(
          weightKg: weightKg,
          heightCm: heightCm,
          age: age,
          gender: gender,
        ) *
        activityLevel.multiplier;
  }

  static CalorieTargets calorieTargets(double tdee) {
    return CalorieTargets(
      maintenance: tdee,
      mildDeficit: tdee - 250,
      moderateDeficit: tdee - 500,
      aggressiveDeficit: tdee - 750,
      surplus: tdee + 300,
    );
  }

  /// Macro split for a given calorie target: protein 1.8g/kg bodyweight,
  /// fat 25% of calories, remainder from carbs.
  static Macros macros({
    required double calorieTarget,
    required double weightKg,
  }) {
    final proteinG = weightKg * 1.8;
    final proteinCals = proteinG * 4;
    final fatCals = calorieTarget * 0.25;
    final fatG = fatCals / 9;
    final carbCals = calorieTarget - proteinCals - fatCals;
    final carbG = carbCals / 4;
    return Macros(proteinG: proteinG, fatG: fatG, carbG: carbG < 0 ? 0 : carbG);
  }
}
