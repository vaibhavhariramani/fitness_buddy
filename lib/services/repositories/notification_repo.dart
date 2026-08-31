import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_notification.dart';

class NotificationRepo {
  final FirebaseFirestore _db;

  NotificationRepo({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<AppNotification>> watchAll(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => AppNotification.fromJson(d.id, d.data()))
                  .toList(),
        );
  }

  Stream<int> watchUnreadCount(String uid) {
    return _col(
      uid,
    ).where('read', isEqualTo: false).snapshots().map((snap) => snap.size);
  }

  Future<void> markRead(String uid, String notificationId) {
    return _col(uid).doc(notificationId).update({'read': true});
  }

  Future<void> markAllRead(String uid) async {
    final unread = await _col(uid).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
