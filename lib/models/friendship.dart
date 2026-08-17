import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  final String id;
  final List<String> uids;
  final String requestedBy;
  final FriendshipStatus status;
  final DateTime createdAt;

  const Friendship({
    required this.id,
    required this.uids,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
  });

  String otherUid(String myUid) =>
      uids.firstWhere((u) => u != myUid, orElse: () => myUid);

  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Map<String, dynamic> toJson() => {
    'uids': uids,
    'requestedBy': requestedBy,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Friendship.fromJson(String id, Map<String, dynamic> json) =>
      Friendship(
        id: id,
        uids: List<String>.from(json['uids'] as List? ?? []),
        requestedBy: json['requestedBy'] as String? ?? '',
        status: FriendshipStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => FriendshipStatus.pending,
        ),
        createdAt:
            (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
