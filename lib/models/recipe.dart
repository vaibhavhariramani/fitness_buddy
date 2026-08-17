class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final String instructions;
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;
  final List<String> tags;

  const Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.calories,
    this.proteinG = 0,
    this.carbG = 0,
    this.fatG = 0,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'ingredients': ingredients,
    'instructions': instructions,
    'calories': calories,
    'proteinG': proteinG,
    'carbG': carbG,
    'fatG': fatG,
    'tags': tags,
  };

  factory Recipe.fromJson(String id, Map<String, dynamic> json) => Recipe(
    id: id,
    name: json['name'] as String? ?? '',
    ingredients: List<String>.from(json['ingredients'] as List? ?? []),
    instructions: json['instructions'] as String? ?? '',
    calories: (json['calories'] as num?)?.toDouble() ?? 0,
    proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
    carbG: (json['carbG'] as num?)?.toDouble() ?? 0,
    fatG: (json['fatG'] as num?)?.toDouble() ?? 0,
    tags: List<String>.from(json['tags'] as List? ?? []),
  );

  /// Fraction of this recipe's ingredients present in [available] (case-insensitive).
  double matchScore(Set<String> available) {
    if (ingredients.isEmpty) return 0;
    final normalizedAvailable =
        available.map((e) => e.toLowerCase().trim()).toSet();
    final matched =
        ingredients
            .where((i) => normalizedAvailable.contains(i.toLowerCase().trim()))
            .length;
    return matched / ingredients.length;
  }
}
