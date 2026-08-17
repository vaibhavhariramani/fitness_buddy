import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/expense_entry.dart';

class ExpenseRepo {
  final FirebaseFirestore _db;

  ExpenseRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('expenses');

  Future<String> add(String uid, ExpenseEntry entry) async {
    final ref = await _col(uid).add(entry.toJson());
    return ref.id;
  }

  Future<void> delete(String uid, String expenseId) {
    return _col(uid).doc(expenseId).delete();
  }

  Stream<List<ExpenseEntry>> watchAll(String uid) {
    return _col(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => ExpenseEntry.fromJson(d.id, d.data()))
                  .toList(),
        );
  }

  Stream<List<ExpenseEntry>> watchRange(
    String uid,
    DateTime start,
    DateTime end,
  ) {
    return _col(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => ExpenseEntry.fromJson(d.id, d.data()))
                  .toList(),
        );
  }
}
