import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/nutrition/models/food.dart';

/// A single food within a [SavedMeal], with its nutrition frozen at the
/// point the meal was saved (consistent with how MealEntry itself already
/// freezes absolute nutrition — no re-fetch, no staleness surprises).
class SavedMealItem {
  final String foodId;
  final String foodName;
  final String? brand;
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

  const SavedMealItem({
    required this.foodId,
    required this.foodName,
    this.brand,
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

  Map<String, dynamic> toJson() => {
    'foodId': foodId,
    'foodName': foodName,
    'brand': brand,
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

  factory SavedMealItem.fromJson(Map<String, dynamic> json) => SavedMealItem(
    foodId: json['foodId'] as String? ?? '',
    foodName: json['foodName'] as String? ?? 'Unnamed food',
    brand: json['brand'] as String?,
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

class SavedMeal {
  final String id;
  final String name;
  final List<SavedMealItem> items;
  final DateTime createdAt;

  const SavedMeal({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  double get totalCalories =>
      items.fold(0, (s, i) => s + i.caloriesPer100g * i.grams / 100);
  double get totalProteinG =>
      items.fold(0, (s, i) => s + i.proteinPer100g * i.grams / 100);
  double get totalCarbG =>
      items.fold(0, (s, i) => s + i.carbPer100g * i.grams / 100);
  double get totalFatG =>
      items.fold(0, (s, i) => s + i.fatPer100g * i.grams / 100);

  Map<String, dynamic> toJson() => {
    'name': name,
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory SavedMeal.fromJson(String id, Map<String, dynamic> json) => SavedMeal(
    id: id,
    name: json['name'] as String? ?? 'Unnamed meal',
    items:
        (json['items'] as List? ?? [])
            .map(
              (i) =>
                  SavedMealItem.fromJson(Map<String, dynamic>.from(i as Map)),
            )
            .toList(),
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
