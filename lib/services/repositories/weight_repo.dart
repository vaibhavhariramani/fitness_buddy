import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/weight_entry.dart';

class WeightRepo {
  final FirebaseFirestore _db;

  WeightRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('weightLogs');

  Future<String> add(String uid, WeightEntry entry) async {
    final ref = await _col(uid).add(entry.toJson());
    return ref.id;
  }

  Stream<List<WeightEntry>> watchAll(String uid) {
    return _col(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => WeightEntry.fromJson(d.id, d.data()))
                  .toList(),
        );
  }

  Future<void> update(String uid, String entryId, Map<String, dynamic> patch) {
    return _col(uid).doc(entryId).update(patch);
  }

  Future<void> delete(String uid, String entryId) {
    return _col(uid).doc(entryId).delete();
  }
}
