import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderUid;
  final String text;
  final DateTime sentAt;

  const Message({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
    'senderUid': senderUid,
    'text': text,
    'sentAt': Timestamp.fromDate(sentAt),
  };

  factory Message.fromJson(String id, Map<String, dynamic> json) => Message(
    id: id,
    senderUid: json['senderUid'] as String? ?? '',
    text: json['text'] as String? ?? '',
    sentAt: (json['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
