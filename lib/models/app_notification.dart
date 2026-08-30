import 'package:cloud_firestore/cloud_firestore.dart';

/// A notification a Cloud Function wrote to `users/{uid}/notifications` —
/// currently just friend-activity pings, but generic enough to cover future
/// notification types without a schema change.
class AppNotification {
  final String id;
  final String type;
  final String actorUid;
  final String actorName;
  final String? actorPhotoUrl;
  final String message;

  /// Where tapping the notification should navigate to.
  final String route;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorName,
    this.actorPhotoUrl,
    required this.message,
    required this.route,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(String id, Map<String, dynamic> json) {
    return AppNotification(
      id: id,
      type: json['type'] as String? ?? 'activity',
      actorUid: json['actorUid'] as String? ?? '',
      actorName: json['actorName'] as String? ?? '',
      actorPhotoUrl: json['actorPhotoUrl'] as String?,
      message: json['message'] as String? ?? '',
      route: json['route'] as String? ?? '/social',
      read: json['read'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
