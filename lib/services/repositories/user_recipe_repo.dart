import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_recipe.dart';

class UserRecipeRepo {
  final FirebaseFirestore _db;

  UserRecipeRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('userRecipes');

  Future<String> add(String uid, UserRecipe recipe) async {
    final ref = await _col(uid).add(recipe.toJson());
    return ref.id;
  }

  Future<void> delete(String uid, String recipeId) {
    return _col(uid).doc(recipeId).delete();
  }

  Stream<List<UserRecipe>> watchAll(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => UserRecipe.fromJson(d.id, d.data()))
                  .toList(),
        );
  }
}
