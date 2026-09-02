import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/wellness_reminder.dart';

class WellnessReminderRepo {
  final FirebaseFirestore _db;

  WellnessReminderRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('wellnessReminders');

  Future<String> add(String uid, WellnessReminder reminder) async {
    final ref = await _col(uid).add(reminder.toJson());
    return ref.id;
  }

  Future<void> update(
    String uid,
    String reminderId,
    Map<String, dynamic> patch,
  ) {
    return _col(uid).doc(reminderId).update(patch);
  }

  Future<void> delete(String uid, String reminderId) {
    return _col(uid).doc(reminderId).delete();
  }

  Stream<List<WellnessReminder>> watchAll(String uid) {
    return _col(uid)
        .orderBy('minutesSinceMidnight')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => WellnessReminder.fromJson(d.id, d.data()))
                  .toList(),
        );
  }
}
