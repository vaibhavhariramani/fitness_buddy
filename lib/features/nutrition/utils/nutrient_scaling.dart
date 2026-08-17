import '../../../models/meal_entry.dart';

/// Recovers a "per 100g" nutrition figure from a [MealEntry]'s frozen
/// absolute values, using the fact that `quantity` was stored as
/// `gramsLogged / 100` at save time (see ServingConfirmPage). Used to
/// reconstruct a browsable Food from meal history (recent foods) and to
/// snapshot a diary entry into a saved-meal item without a network refetch.
class ScaledNutrients {
  final double calories;
  final double protein;
  final double carb;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? satFat;
  final double? sodium;

  const ScaledNutrients({
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
    this.fiber,
    this.sugar,
    this.satFat,
    this.sodium,
  });
}

ScaledNutrients per100gFromEntry(MealEntry m) {
  final q = m.quantity > 0 ? m.quantity : 1.0;
  return ScaledNutrients(
    calories: m.calories / q,
    protein: m.proteinG / q,
    carb: m.carbG / q,
    fat: m.fatG / q,
    fiber: m.fiberG == null ? null : m.fiberG! / q,
    sugar: m.sugarG == null ? null : m.sugarG! / q,
    satFat: m.satFatG == null ? null : m.satFatG! / q,
    sodium: m.sodiumMg == null ? null : m.sodiumMg! / q,
  );
}
