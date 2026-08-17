import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/nutrition/models/food.dart';

/// A single ingredient within a [UserRecipe], with its nutrition frozen at
/// the point it was added — same staleness/simplicity reasoning as
/// SavedMealItem.
class RecipeIngredient {
  final String foodId;
  final String foodName;
  final FoodSource source;
  final double grams;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? satFatPer100g;
  final double? sodiumPer100gMg;

  const RecipeIngredient({
    required this.foodId,
    required this.foodName,
    required this.source,
    required this.grams,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.satFatPer100g,
    this.sodiumPer100gMg,
  });

  factory RecipeIngredient.fromFood(Food food, {required double grams}) =>
      RecipeIngredient(
        foodId: food.id,
        foodName: food.name,
        source: food.source,
        grams: grams,
        caloriesPer100g: food.caloriesPer100g,
        proteinPer100g: food.proteinPer100g,
        carbPer100g: food.carbPer100g,
        fatPer100g: food.fatPer100g,
        fiberPer100g: food.fiberPer100g,
        sugarPer100g: food.sugarPer100g,
        satFatPer100g: food.satFatPer100g,
        sodiumPer100gMg: food.sodiumPer100gMg,
      );

  Map<String, dynamic> toJson() => {
    'foodId': foodId,
    'foodName': foodName,
    'source': source.name,
    'grams': grams,
    'caloriesPer100g': caloriesPer100g,
    'proteinPer100g': proteinPer100g,
    'carbPer100g': carbPer100g,
    'fatPer100g': fatPer100g,
    'fiberPer100g': fiberPer100g,
    'sugarPer100g': sugarPer100g,
    'satFatPer100g': satFatPer100g,
    'sodiumPer100gMg': sodiumPer100gMg,
  };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        foodId: json['foodId'] as String? ?? '',
        foodName: json['foodName'] as String? ?? 'Unnamed food',
        source: FoodSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => FoodSource.custom,
        ),
        grams: (json['grams'] as num?)?.toDouble() ?? 100,
        caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble() ?? 0,
        proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0,
        carbPer100g: (json['carbPer100g'] as num?)?.toDouble() ?? 0,
        fatPer100g: (json['fatPer100g'] as num?)?.toDouble() ?? 0,
        fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
        sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
        satFatPer100g: (json['satFatPer100g'] as num?)?.toDouble(),
        sodiumPer100gMg: (json['sodiumPer100gMg'] as num?)?.toDouble(),
      );
}

class UserRecipe {
  final String id;
  final String name;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final DateTime createdAt;

  const UserRecipe({
    required this.id,
    required this.name,
    required this.servings,
    required this.ingredients,
    required this.createdAt,
  });

  double get totalCalories =>
      ingredients.fold(0, (s, i) => s + i.caloriesPer100g * i.grams / 100);
  double get totalProteinG =>
      ingredients.fold(0, (s, i) => s + i.proteinPer100g * i.grams / 100);
  double get totalCarbG =>
      ingredients.fold(0, (s, i) => s + i.carbPer100g * i.grams / 100);
  double get totalFatG =>
      ingredients.fold(0, (s, i) => s + i.fatPer100g * i.grams / 100);

  double get caloriesPerServing =>
      servings > 0 ? totalCalories / servings : totalCalories;
  double get proteinPerServing =>
      servings > 0 ? totalProteinG / servings : totalProteinG;
  double get carbPerServing =>
      servings > 0 ? totalCarbG / servings : totalCarbG;
  double get fatPerServing => servings > 0 ? totalFatG / servings : totalFatG;

  Map<String, dynamic> toJson() => {
    'name': name,
    'servings': servings,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory UserRecipe.fromJson(String id, Map<String, dynamic> json) =>
      UserRecipe(
        id: id,
        name: json['name'] as String? ?? 'Unnamed recipe',
        servings: (json['servings'] as num?)?.toInt() ?? 1,
        ingredients:
            (json['ingredients'] as List? ?? [])
                .map(
                  (i) => RecipeIngredient.fromJson(
                    Map<String, dynamic>.from(i as Map),
                  ),
                )
                .toList(),
        createdAt:
            (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
