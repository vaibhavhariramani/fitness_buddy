import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { direct, group }

class Chat {
  final String id;
  final ChatType type;
  final List<String> participantUids;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final String? groupName;

  const Chat({
    required this.id,
    required this.type,
    required this.participantUids,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.groupName,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'participantUids': participantUids,
    'participantNames': participantNames,
    'lastMessage': lastMessage,
    'lastMessageAt':
        lastMessageAt == null ? null : Timestamp.fromDate(lastMessageAt!),
    'createdAt': Timestamp.fromDate(createdAt),
    'groupName': groupName,
  };

  factory Chat.fromJson(String id, Map<String, dynamic> json) => Chat(
    id: id,
    type: ChatType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => ChatType.direct,
    ),
    participantUids: List<String>.from(json['participantUids'] as List? ?? []),
    participantNames: Map<String, String>.from(
      json['participantNames'] as Map? ?? {},
    ),
    lastMessage: json['lastMessage'] as String?,
    lastMessageAt: (json['lastMessageAt'] as Timestamp?)?.toDate(),
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    groupName: json['groupName'] as String?,
  );
}
