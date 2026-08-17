import '../../../models/custom_food.dart';
import 'open_food_facts_food.dart';

enum FoodSource { openFoodFacts, custom }

final _servingGramsPattern = RegExp(r'(\d+(\.\d+)?)\s*g');

double? _parseServingGrams(String? text) {
  if (text == null) return null;
  final match = _servingGramsPattern.firstMatch(text);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

/// A food search result, normalized to "per 100g" regardless of whether it
/// came from Open Food Facts or the user's own custom foods — this keeps
/// serving-size scaling math (see ServingConfirmPage) uniform across both
/// sources.
class Food {
  final FoodSource source;
  final String id;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? satFatPer100g;
  final double? sodiumPer100gMg;
  final String? servingDescription;
  final double? servingSizeG;

  /// Fixed gram-quantity quick picks (e.g. 100g / 200g / 500g) offered on the
  /// logging screen for dishes without a natural "serving" unit — set only on
  /// bundled common foods (see `common_foods.dart`), null everywhere else.
  final List<double>? quantityPresetsG;

  const Food({
    required this.source,
    required this.id,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.satFatPer100g,
    this.sodiumPer100gMg,
    this.servingDescription,
    this.servingSizeG,
    this.quantityPresetsG,
  });

  factory Food.fromOpenFoodFacts(OpenFoodFactsFood f) => Food(
    source: FoodSource.openFoodFacts,
    id: f.barcode,
    name: f.name,
    brand: f.brand,
    caloriesPer100g: f.caloriesPer100g ?? 0,
    proteinPer100g: f.proteinPer100g ?? 0,
    carbPer100g: f.carbPer100g ?? 0,
    fatPer100g: f.fatPer100g ?? 0,
    fiberPer100g: f.fiberPer100g,
    sugarPer100g: f.sugarPer100g,
    satFatPer100g: f.satFatPer100g,
    sodiumPer100gMg: f.sodiumPer100gMg,
    servingDescription: f.servingSizeText,
    servingSizeG: _parseServingGrams(f.servingSizeText),
  );

  factory Food.fromCustomFood(CustomFood f) {
    // per100ml is treated numerically the same as per100g (1ml ~= 1g) —
    // a deliberate Phase 1 simplification.
    final factor =
        f.basis == NutritionBasis.perServing
            ? 100 / (f.servingSizeG ?? 100)
            : 1.0;
    return Food(
      source: FoodSource.custom,
      id: f.id,
      name: f.name,
      brand: f.brand,
      caloriesPer100g: f.calories * factor,
      proteinPer100g: f.proteinG * factor,
      carbPer100g: f.carbG * factor,
      fatPer100g: f.fatG * factor,
      fiberPer100g: f.fiberG == null ? null : f.fiberG! * factor,
      sugarPer100g: f.sugarG == null ? null : f.sugarG! * factor,
      satFatPer100g: f.satFatG == null ? null : f.satFatG! * factor,
      sodiumPer100gMg: f.sodiumMg == null ? null : f.sodiumMg! * factor,
      servingDescription: f.servingDescription,
      servingSizeG: f.servingSizeG,
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source.name,
    'id': id,
    'name': name,
    'brand': brand,
    'caloriesPer100g': caloriesPer100g,
    'proteinPer100g': proteinPer100g,
    'carbPer100g': carbPer100g,
    'fatPer100g': fatPer100g,
    'fiberPer100g': fiberPer100g,
    'sugarPer100g': sugarPer100g,
    'satFatPer100g': satFatPer100g,
    'sodiumPer100gMg': sodiumPer100gMg,
    'servingDescription': servingDescription,
    'servingSizeG': servingSizeG,
    'quantityPresetsG': quantityPresetsG,
  };

  factory Food.fromJson(Map<String, dynamic> json) => Food(
    source: FoodSource.values.firstWhere(
      (s) => s.name == json['source'],
      orElse: () => FoodSource.openFoodFacts,
    ),
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    brand: json['brand'] as String?,
    caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble() ?? 0,
    proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0,
    carbPer100g: (json['carbPer100g'] as num?)?.toDouble() ?? 0,
    fatPer100g: (json['fatPer100g'] as num?)?.toDouble() ?? 0,
    fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
    sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
    satFatPer100g: (json['satFatPer100g'] as num?)?.toDouble(),
    sodiumPer100gMg: (json['sodiumPer100gMg'] as num?)?.toDouble(),
    servingDescription: json['servingDescription'] as String?,
    servingSizeG: (json['servingSizeG'] as num?)?.toDouble(),
    quantityPresetsG:
        (json['quantityPresetsG'] as List?)
            ?.map((v) => (v as num).toDouble())
            .toList(),
  );
}
