import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType {
  breakfast,
  morningSnack,
  lunch,
  afternoonSnack,
  dinner,
  eveningSnack,
}

extension MealTypeLabel on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.morningSnack:
        return 'Morning Snack';
      case MealType.lunch:
        return 'Lunch';
      case MealType.afternoonSnack:
        return 'Afternoon Snack';
      case MealType.dinner:
        return 'Dinner';
      case MealType.eveningSnack:
        return 'Evening Snack';
    }
  }
}

/// Where a logged entry's numbers came from — used to tailor how a row is
/// displayed (e.g. a food name for search-based entries vs. a plain
/// "Quick add" label for manual ones), not to gate any functionality.
enum MealEntrySource {
  manualQuickAdd,
  foodSearch,
  customFood,
  barcode,
  savedMeal,
  recipe,
}

MealType _parseMealType(String? raw) {
  // Pre-Phase-1 docs only had one generic "snack" type — bucket those into
  // the closest new equivalent rather than losing them to a generic orElse.
  if (raw == 'snack') return MealType.eveningSnack;
  return MealType.values.firstWhere(
    (m) => m.name == raw,
    orElse: () => MealType.eveningSnack,
  );
}

MealEntrySource _parseSource(String? raw) => MealEntrySource.values.firstWhere(
  (s) => s.name == raw,
  orElse: () => MealEntrySource.manualQuickAdd,
);

class MealEntry {
  final String id;
  final DateTime date;
  final MealType mealType;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? satFatG;
  final String? foodName;
  final String? brand;
  final double quantity;
  final String? servingDescription;
  final MealEntrySource source;
  final String? sourceFoodId;
  final String? photoUrl;
  final bool manualEntry;
  final DateTime createdAt;

  const MealEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.calories,
    this.proteinG = 0,
    this.carbG = 0,
    this.fatG = 0,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.satFatG,
    this.foodName,
    this.brand,
    this.quantity = 1.0,
    this.servingDescription,
    this.source = MealEntrySource.manualQuickAdd,
    this.sourceFoodId,
    this.photoUrl,
    this.manualEntry = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'mealType': mealType.name,
    'calories': calories,
    'proteinG': proteinG,
    'carbG': carbG,
    'fatG': fatG,
    'fiberG': fiberG,
    'sugarG': sugarG,
    'sodiumMg': sodiumMg,
    'satFatG': satFatG,
    'foodName': foodName,
    'brand': brand,
    'quantity': quantity,
    'servingDescription': servingDescription,
    'source': source.name,
    'sourceFoodId': sourceFoodId,
    'photoUrl': photoUrl,
    'manualEntry': manualEntry,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory MealEntry.fromJson(String id, Map<String, dynamic> json) => MealEntry(
    id: id,
    date: (json['date'] as Timestamp).toDate(),
    mealType: _parseMealType(json['mealType'] as String?),
    calories: (json['calories'] as num).toDouble(),
    proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
    carbG: (json['carbG'] as num?)?.toDouble() ?? 0,
    fatG: (json['fatG'] as num?)?.toDouble() ?? 0,
    fiberG: (json['fiberG'] as num?)?.toDouble(),
    sugarG: (json['sugarG'] as num?)?.toDouble(),
    sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
    satFatG: (json['satFatG'] as num?)?.toDouble(),
    foodName: json['foodName'] as String?,
    brand: json['brand'] as String?,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    servingDescription: json['servingDescription'] as String?,
    source: _parseSource(json['source'] as String?),
    sourceFoodId: json['sourceFoodId'] as String?,
    photoUrl: json['photoUrl'] as String?,
    manualEntry: json['manualEntry'] as bool? ?? false,
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
