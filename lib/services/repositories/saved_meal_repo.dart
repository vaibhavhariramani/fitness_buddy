import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/saved_meal.dart';

class SavedMealRepo {
  final FirebaseFirestore _db;

  SavedMealRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('savedMeals');

  Future<String> add(String uid, SavedMeal meal) async {
    final ref = await _col(uid).add(meal.toJson());
    return ref.id;
  }

  Future<void> delete(String uid, String mealId) {
    return _col(uid).doc(mealId).delete();
  }

  Stream<List<SavedMeal>> watchAll(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SavedMeal.fromJson(d.id, d.data())).toList(),
        );
  }
}
