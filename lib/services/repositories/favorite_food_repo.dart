import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/nutrition/models/food.dart';

class FavoriteFoodRepo {
  final FirebaseFirestore _db;

  FavoriteFoodRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('favoriteFoods');

  Future<void> add(String uid, Food food) {
    return _col(
      uid,
    ).doc(food.id).set({...food.toJson(), 'favoritedAt': Timestamp.now()});
  }

  Future<void> remove(String uid, String foodId) {
    return _col(uid).doc(foodId).delete();
  }

  Stream<List<Food>> watchAll(String uid) {
    return _col(uid)
        .orderBy('favoritedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Food.fromJson(d.data())).toList());
  }
}
