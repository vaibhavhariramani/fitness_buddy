import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/meal_entry.dart';

class MealRepo {
  final FirebaseFirestore _db;

  MealRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('meals');

  Future<String> add(String uid, MealEntry entry) async {
    final ref = await _col(uid).add(entry.toJson());
    return ref.id;
  }

  Future<void> update(String uid, String mealId, Map<String, dynamic> patch) {
    return _col(uid).doc(mealId).update(patch);
  }

  Future<void> delete(String uid, String mealId) {
    return _col(uid).doc(mealId).delete();
  }

  Future<void> addBatch(String uid, List<MealEntry> entries) async {
    final batch = _db.batch();
    for (final entry in entries) {
      batch.set(_col(uid).doc(), entry.toJson());
    }
    await batch.commit();
  }

  Stream<List<MealEntry>> watchForDate(String uid, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MealEntry.fromJson(d.id, d.data())).toList(),
        );
  }

  Stream<List<MealEntry>> watchRange(String uid, DateTime start, DateTime end) {
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MealEntry.fromJson(d.id, d.data())).toList(),
        );
  }
}
