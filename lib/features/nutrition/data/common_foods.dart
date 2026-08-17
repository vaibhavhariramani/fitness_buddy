import '../models/food.dart';

/// A small bundled list of everyday staple foods that should always be
/// findable by search, independent of Open Food Facts' patchy coverage of
/// generic (non-barcoded/home-cooked) items and independent of network
/// access or its occasional outages. Nutrition values are typical/estimated
/// figures for the generic dish or product, not tied to one specific brand
/// or barcode — labelled "typical values" in the brand field for honesty.
final List<Food> commonFoods = [
  const Food(
    source: FoodSource.custom,
    id: 'common-plain-oats',
    name: 'Oats (plain, dry)',
    brand: 'Generic — typical values',
    caloriesPer100g: 375,
    proteinPer100g: 11,
    carbPer100g: 60,
    fatPer100g: 8,
    fiberPer100g: 9,
    sugarPer100g: 1,
    satFatPer100g: 1.5,
    servingDescription: '1 scoop (~40g)',
    servingSizeG: 40,
  ),
  const Food(
    source: FoodSource.custom,
    id: 'common-oats-whey-protein',
    name: 'Oats with whey protein',
    brand: 'Generic — 1 scoop oats + 1 scoop whey',
    caloriesPer100g: 386,
    proteinPer100g: 40.6,
    carbPer100g: 38.6,
    fatPer100g: 7.4,
    fiberPer100g: 5.1,
    sugarPer100g: 2,
    satFatPer100g: 2.3,
    servingDescription: '1 scoop oats (~40g) + 1 scoop whey protein (~30g)',
    servingSizeG: 70,
  ),
  const Food(
    source: FoodSource.custom,
    id: 'common-chicken-curry',
    name: 'Chicken curry',
    brand: 'Generic — typical values',
    caloriesPer100g: 165,
    proteinPer100g: 13,
    carbPer100g: 6,
    fatPer100g: 10,
    fiberPer100g: 1,
    sugarPer100g: 3,
    satFatPer100g: 3,
    sodiumPer100gMg: 380,
    servingDescription: 'Standard portion (~300g, excl. rice)',
    servingSizeG: 300,
    quantityPresetsG: [100, 200, 300, 500],
  ),
  const Food(
    source: FoodSource.custom,
    id: 'common-boiled-rice',
    name: 'Boiled rice (white)',
    brand: 'Generic — typical values',
    caloriesPer100g: 130,
    proteinPer100g: 2.7,
    carbPer100g: 28,
    fatPer100g: 0.3,
    fiberPer100g: 0.4,
    sugarPer100g: 0,
    satFatPer100g: 0.1,
    sodiumPer100gMg: 1,
    servingDescription: 'Standard portion (~180g)',
    servingSizeG: 180,
    quantityPresetsG: [100, 200, 300, 500],
  ),
];
