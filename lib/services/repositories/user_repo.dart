import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_profile.dart';
import '../../core/utils/streak.dart';

class UserRepo {
  final FirebaseFirestore _db;

  UserRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _directoryDoc(String uid) =>
      _db.collection('userDirectory').doc(uid);

  CollectionReference<Map<String, dynamic>> _fcmTokensCol(String uid) =>
      _doc(uid).collection('fcmTokens');

  Future<void> createProfile(UserProfile profile) async {
    await _doc(profile.uid).set(profile.toJson());
    await _directoryDoc(profile.uid).set(
      UserDirectoryEntry(
        uid: profile.uid,
        displayName: profile.displayName,
        email: profile.email,
      ).toJson(),
    );
  }

  Future<UserDirectoryEntry?> getDirectoryEntry(String uid) async {
    final snap = await _directoryDoc(uid).get();
    if (!snap.exists) return null;
    return UserDirectoryEntry.fromJson(uid, snap.data()!);
  }

  Future<UserDirectoryEntry?> findDirectoryEntryByEmail(String email) async {
    final snap =
        await _db
            .collection('userDirectory')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (snap.docs.isEmpty) return null;
    return UserDirectoryEntry.fromJson(
      snap.docs.first.id,
      snap.docs.first.data(),
    );
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromJson(uid, snap.data()!);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromJson(uid, snap.data()!);
    });
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> patch) {
    return _doc(uid).update(patch);
  }

  /// Updates the display name on both the profile doc and the directory
  /// entry used for friend lookups, so they can't drift out of sync.
  Future<void> updateDisplayName(String uid, String displayName) async {
    await _doc(uid).update({'displayName': displayName});
    await _directoryDoc(uid).update({'displayName': displayName});
  }

  /// Registers a device's FCM token so Cloud Functions can push to it — doc
  /// id is the token itself, so re-saving the same token on relaunch is a
  /// harmless no-op merge rather than a growing pile of duplicates.
  Future<void> saveFcmToken(String uid, String token) {
    return _fcmTokensCol(uid).doc(token).set({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Called on sign-out so a shared/borrowed device stops receiving this
  /// user's push notifications.
  Future<void> removeFcmToken(String uid, String token) {
    return _fcmTokensCol(uid).doc(token).delete();
  }

  /// Recomputes the streak inside a transaction so concurrent logs on the
  /// same day don't race each other, then returns the resulting count.
  Future<int> registerActivityAndGetStreak(String uid) {
    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(_doc(uid));
      final data = snap.data() ?? {};
      final previousStreak = (data['streakCount'] as num?)?.toInt() ?? 0;
      final previousLastLogDate = (data['lastLogDate'] as Timestamp?)?.toDate();

      final result = StreakCalculator.onActivityLogged(
        previousStreak: previousStreak,
        previousLastLogDate: previousLastLogDate,
      );

      tx.set(_doc(uid), {
        'streakCount': result.streakCount,
        'lastLogDate': Timestamp.fromDate(result.lastLogDate),
      }, SetOptions(merge: true));

      return result.streakCount;
    });
  }
}
