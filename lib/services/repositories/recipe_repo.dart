import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/recipe.dart';

/// Recipes are a seeded, mostly-static, public-read collection (see
/// `firestore.rules` — clients cannot write to it). Seeding is done once via
/// the Firebase console/emulator import, not from the app.
class RecipeRepo {
  final FirebaseFirestore _db;

  RecipeRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('recipes');

  Future<List<Recipe>> getAll() async {
    final snap = await _col.get();
    return snap.docs.map((d) => Recipe.fromJson(d.id, d.data())).toList();
  }

  /// Ranks all recipes by how many of [availableIngredients] they use,
  /// dropping anything below [minMatchScore].
  Future<List<Recipe>> recommend(
    Set<String> availableIngredients, {
    double minMatchScore = 0.4,
  }) async {
    final recipes = await getAll();
    final scored =
        recipes
            .map((r) => (recipe: r, score: r.matchScore(availableIngredients)))
            .where((e) => e.score >= minMatchScore)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.recipe).toList();
  }
}
