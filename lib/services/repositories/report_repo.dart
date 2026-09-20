import 'package:cloud_firestore/cloud_firestore.dart';

/// Write-only moderation trail for reported/blocked users — satisfies
/// Guideline 1.2 (any app carrying user-generated content needs a working
/// report path), without needing a moderation dashboard for v1. Reports are
/// reviewed via the Firebase console; no client, including the reporter,
/// can read them back (see firestore.rules).
class ReportRepo {
  final FirebaseFirestore _db;

  ReportRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<void> submit({
    required String reporterUid,
    required String reportedUid,
    required String reportedName,
    required String reason,
    String? chatId,
  }) {
    return _db.collection('reports').add({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reportedName': reportedName,
      'reason': reason,
      'chatId': chatId,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
