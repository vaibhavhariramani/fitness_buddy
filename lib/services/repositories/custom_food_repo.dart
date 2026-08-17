import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/custom_food.dart';

class CustomFoodRepo {
  final FirebaseFirestore _db;

  CustomFoodRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('customFoods');

  Future<String> add(String uid, CustomFood food) async {
    final ref = await _col(uid).add(food.toJson());
    return ref.id;
  }

  Future<void> update(String uid, String foodId, Map<String, dynamic> patch) {
    return _col(uid).doc(foodId).update(patch);
  }

  Future<void> delete(String uid, String foodId) {
    return _col(uid).doc(foodId).delete();
  }

  Stream<List<CustomFood>> watchAll(String uid) {
    return _col(uid)
        .orderBy('name')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => CustomFood.fromJson(d.id, d.data()))
                  .toList(),
        );
  }
}
