/// Raw parse of an Open Food Facts product JSON object. All nutrient fields
/// are nullable — OFF's data completeness varies widely by product. See
/// Food.fromOpenFoodFacts for the normalized shape used by the rest of the
/// app.
class OpenFoodFactsFood {
  final String barcode;
  final String name;
  final String? brand;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbPer100g;
  final double? fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? satFatPer100g;
  final double? sodiumPer100gMg;
  final String? servingSizeText;

  const OpenFoodFactsFood({
    required this.barcode,
    required this.name,
    this.brand,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbPer100g,
    this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.satFatPer100g,
    this.sodiumPer100gMg,
    this.servingSizeText,
  });

  factory OpenFoodFactsFood.fromJson(Map<String, dynamic> product) {
    final nutriments = Map<String, dynamic>.from(
      product['nutriments'] as Map? ?? {},
    );
    double? num_(String key) => (nutriments[key] as num?)?.toDouble();

    final name = (product['product_name'] as String?)?.trim();
    final sodiumG = num_('sodium_100g');

    return OpenFoodFactsFood(
      barcode: product['code'] as String? ?? '',
      name: (name == null || name.isEmpty) ? 'Unknown food' : name,
      brand: (product['brands'] as String?)?.split(',').first.trim(),
      caloriesPer100g: num_('energy-kcal_100g'),
      proteinPer100g: num_('proteins_100g'),
      carbPer100g: num_('carbohydrates_100g'),
      fatPer100g: num_('fat_100g'),
      fiberPer100g: num_('fiber_100g'),
      sugarPer100g: num_('sugars_100g'),
      satFatPer100g: num_('saturated-fat_100g'),
      // OFF reports sodium in grams per 100g; the rest of this app stores
      // sodium in milligrams.
      sodiumPer100gMg: sodiumG == null ? null : sodiumG * 1000,
      servingSizeText: product['serving_size'] as String?,
    );
  }
}
