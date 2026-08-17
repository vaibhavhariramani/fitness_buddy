/// A curated, locally-bundled exercise (see assets/data/exercises.json).
/// All factual content (muscles/equipment/instructions/coaching notes) is
/// local and offline. A subset of exercises additionally carry a real photo
/// URL from wger.de (only where a confident, manually-reviewed match to
/// wger's separate catalog exists) — see widgets/exercise_visual.dart, which
/// falls back to the original pose pictogram whenever no photo is set or
/// the photo fails to load.
class Exercise {
  final String id;
  final String name;
  final String category;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipment;
  final String difficulty;
  final String preparation;
  final String execution;
  final List<String> formTips;
  final List<String> commonMistakes;
  final List<String> safetyNotes;
  final List<String> substitutes;
  final int calorieEstimatePerSet;
  final int avgSecondsPerSet;
  final String? wgerImageUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    required this.preparation,
    required this.execution,
    required this.formTips,
    this.commonMistakes = const [],
    this.safetyNotes = const [],
    this.substitutes = const [],
    required this.calorieEstimatePerSet,
    required this.avgSecondsPerSet,
    this.wgerImageUrl,
  });

  String get primaryMuscleNames =>
      primaryMuscles.isEmpty ? 'Full body' : primaryMuscles.join(', ');

  String get equipmentNames =>
      equipment.isEmpty ? 'Bodyweight' : equipment.join(', ');

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? '';
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: category,
      primaryMuscles: (json['primaryMuscles'] as List? ?? []).cast<String>(),
      secondaryMuscles:
          (json['secondaryMuscles'] as List? ?? []).cast<String>(),
      equipment: (json['equipment'] as List? ?? []).cast<String>(),
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      preparation: json['preparation'] as String? ?? '',
      execution: json['execution'] as String? ?? '',
      formTips: (json['formTips'] as List? ?? []).cast<String>(),
      commonMistakes: (json['commonMistakes'] as List? ?? []).cast<String>(),
      safetyNotes: (json['safetyNotes'] as List? ?? []).cast<String>(),
      substitutes: (json['substitutes'] as List? ?? []).cast<String>(),
      calorieEstimatePerSet:
          json['calorieEstimatePerSet'] as int? ??
          _calorieEstimateFor(category),
      avgSecondsPerSet:
          json['avgSecondsPerSet'] as int? ?? _avgSecondsFor(category),
      wgerImageUrl: json['wgerImageUrl'] as String?,
    );
  }

  static const _metByCategory = {
    'cardio': 8.0,
    'legs': 6.0,
    'back': 5.5,
    'chest': 5.0,
    'shoulders': 4.5,
    'arms': 4.0,
    'core': 4.0,
  };

  static int _calorieEstimateFor(String category) {
    final met = _metByCategory[category.toLowerCase()] ?? 4.0;
    // kcal = MET * 3.5 * weightKg / 200 * durationMinutes, 70kg adult, 45s set.
    final kcal = met * 3.5 * 70 / 200 * (45 / 60);
    return kcal.round();
  }

  static const _secondsByCategory = {
    'cardio': 60,
    'legs': 50,
    'back': 45,
    'chest': 40,
    'shoulders': 40,
    'core': 35,
    'arms': 35,
  };

  static int _avgSecondsFor(String category) =>
      _secondsByCategory[category.toLowerCase()] ?? 40;
}
