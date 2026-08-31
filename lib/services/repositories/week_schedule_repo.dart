import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/week_schedule.dart';

final _docIdFormat = DateFormat('yyyy-MM-dd');

/// This-week-only overrides to the permanent [WeeklyRoutine] — one document
/// per calendar week, keyed by that week's Monday date, so "reschedule
/// Tuesday to Thursday" never touches the routine other weeks still follow.
class WeekScheduleRepo {
  final FirebaseFirestore _db;

  WeekScheduleRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('weekSchedule');

  Stream<WeekSchedule> watchWeek(String uid, DateTime weekStart) {
    final id = _docIdFormat.format(weekStart);
    return _col(uid)
        .doc(id)
        .snapshots()
        .map((snap) => WeekSchedule.fromJson(weekStart, snap.data()));
  }

  Future<void> setOverride(
    String uid,
    DateTime weekStart,
    int isoWeekday,
    String? planId,
  ) async {
    final id = _docIdFormat.format(weekStart);
    await _col(uid).doc(id).set({
      'weekStart': Timestamp.fromDate(weekStart),
      'overrides': {isoWeekday.toString(): planId},
    }, SetOptions(merge: true));
  }

  /// Reverts a single day back to whatever the permanent routine says.
  Future<void> clearOverride(
    String uid,
    DateTime weekStart,
    int isoWeekday,
  ) async {
    final id = _docIdFormat.format(weekStart);
    await _col(uid).doc(id).set({
      'overrides': {isoWeekday.toString(): FieldValue.delete()},
    }, SetOptions(merge: true));
  }
}
