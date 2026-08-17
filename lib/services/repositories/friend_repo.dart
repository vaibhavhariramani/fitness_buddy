import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/friendship.dart';

class FriendRepo {
  final FirebaseFirestore _db;

  FriendRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('friendships');

  Future<void> sendRequest({required String myUid, required String otherUid}) {
    final id = Friendship.idFor(myUid, otherUid);
    return _col
        .doc(id)
        .set(
          Friendship(
            id: id,
            uids: [myUid, otherUid],
            requestedBy: myUid,
            status: FriendshipStatus.pending,
            createdAt: DateTime.now(),
          ).toJson(),
        );
  }

  Future<void> respondToRequest({
    required String myUid,
    required String otherUid,
    required bool accept,
  }) {
    final id = Friendship.idFor(myUid, otherUid);
    if (accept) {
      return _col.doc(id).update({'status': FriendshipStatus.accepted.name});
    }
    return _col.doc(id).delete();
  }

  Future<void> removeFriend({required String myUid, required String otherUid}) {
    return _col.doc(Friendship.idFor(myUid, otherUid)).delete();
  }

  Stream<List<Friendship>> watchFriendships(String uid) {
    return _col
        .where('uids', arrayContains: uid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => Friendship.fromJson(d.id, d.data()))
                  .toList(),
        );
  }

  Stream<List<Friendship>> watchAccepted(String uid) {
    return _col
        .where('uids', arrayContains: uid)
        .where('status', isEqualTo: FriendshipStatus.accepted.name)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => Friendship.fromJson(d.id, d.data()))
                  .toList(),
        );
  }

  Stream<List<Friendship>> watchIncomingRequests(String uid) {
    return _col
        .where('uids', arrayContains: uid)
        .where('status', isEqualTo: FriendshipStatus.pending.name)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => Friendship.fromJson(d.id, d.data()))
                  .where((f) => f.requestedBy != uid)
                  .toList(),
        );
  }
}
