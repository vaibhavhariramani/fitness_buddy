import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/weekly_routine.dart';

/// The user's permanent weekly training template — a single document per
/// user (not a growing collection), since there's only ever one "current"
/// routine.
class WeeklyRoutineRepo {
  final FirebaseFirestore _db;

  WeeklyRoutineRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('weeklyRoutine')
      .doc('current');

  Stream<WeeklyRoutine> watch(String uid) {
    return _doc(
      uid,
    ).snapshots().map((snap) => WeeklyRoutine.fromJson(snap.data()));
  }

  Future<void> setDay(String uid, int isoWeekday, String? planId) async {
    await _doc(uid).set({
      'days': {isoWeekday.toString(): planId},
    }, SetOptions(merge: true));
  }
}
