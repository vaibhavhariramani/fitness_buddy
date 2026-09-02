import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/story.dart';

class StoryRepo {
  final FirebaseFirestore _db;

  StoryRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('stories');

  Future<String> add(String uid, Story story) async {
    final ref = await _col(uid).add(story.toJson());
    return ref.id;
  }

  /// Unexpired stories only, oldest first — this is the display-side expiry
  /// gate; physical deletion happens later via a scheduled Cloud Function.
  Stream<List<Story>> watchActive(String uid) {
    return _col(uid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Story.fromJson(d.id, d.data())).toList(),
        );
  }
}
