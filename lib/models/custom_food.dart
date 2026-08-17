import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether the stored calorie/macro values represent 100g, 100ml, or a
/// single serving of this food.
enum NutritionBasis { per100g, per100ml, perServing }

class CustomFood {
  final String id;
  final String name;
  final String? brand;
  final NutritionBasis basis;
  final double? servingSizeG;
  final String? servingDescription;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? satFatG;
  final DateTime createdAt;

  const CustomFood({
    required this.id,
    required this.name,
    this.brand,
    required this.basis,
    this.servingSizeG,
    this.servingDescription,
    required this.calories,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.satFatG,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'brand': brand,
    'basis': basis.name,
    'servingSizeG': servingSizeG,
    'servingDescription': servingDescription,
    'calories': calories,
    'proteinG': proteinG,
    'carbG': carbG,
    'fatG': fatG,
    'fiberG': fiberG,
    'sugarG': sugarG,
    'sodiumMg': sodiumMg,
    'satFatG': satFatG,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory CustomFood.fromJson(String id, Map<String, dynamic> json) =>
      CustomFood(
        id: id,
        name: json['name'] as String? ?? 'Unnamed food',
        brand: json['brand'] as String?,
        basis: NutritionBasis.values.firstWhere(
          (b) => b.name == json['basis'],
          orElse: () => NutritionBasis.per100g,
        ),
        servingSizeG: (json['servingSizeG'] as num?)?.toDouble(),
        servingDescription: json['servingDescription'] as String?,
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
        carbG: (json['carbG'] as num?)?.toDouble() ?? 0,
        fatG: (json['fatG'] as num?)?.toDouble() ?? 0,
        fiberG: (json['fiberG'] as num?)?.toDouble(),
        sugarG: (json['sugarG'] as num?)?.toDouble(),
        sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
        satFatG: (json['satFatG'] as num?)?.toDouble(),
        createdAt:
            (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
