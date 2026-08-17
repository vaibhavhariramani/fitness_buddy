import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/chat.dart';
import '../../models/message.dart';

class ChatRepo {
  final FirebaseFirestore _db;

  ChatRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chatsCol =>
      _db.collection('chats');

  /// Returns the existing direct chat id between the two users, or creates one.
  Future<String> getOrCreateDirectChat({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
  }) async {
    final existing =
        await _chatsCol
            .where('type', isEqualTo: ChatType.direct.name)
            .where('participantUids', arrayContains: myUid)
            .get();

    for (final doc in existing.docs) {
      final uids = List<String>.from(doc.data()['participantUids'] as List);
      if (uids.contains(otherUid)) return doc.id;
    }

    final ref = await _chatsCol.add(
      Chat(
        id: '',
        type: ChatType.direct,
        participantUids: [myUid, otherUid],
        participantNames: {myUid: myName, otherUid: otherName},
        createdAt: DateTime.now(),
      ).toJson(),
    );
    return ref.id;
  }

  Future<String> createGroupChat({
    required String groupName,
    required Map<String, String> participantNames,
  }) async {
    final ref = await _chatsCol.add(
      Chat(
        id: '',
        type: ChatType.group,
        participantUids: participantNames.keys.toList(),
        participantNames: participantNames,
        createdAt: DateTime.now(),
        groupName: groupName,
      ).toJson(),
    );
    return ref.id;
  }

  Stream<List<Chat>> watchChatsFor(String uid) {
    return _chatsCol
        .where('participantUids', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Chat.fromJson(d.id, d.data())).toList(),
        );
  }

  Stream<List<Message>> watchMessages(String chatId) {
    return _chatsCol
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Message.fromJson(d.id, d.data())).toList(),
        );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
  }) async {
    final now = DateTime.now();
    final chatRef = _chatsCol.doc(chatId);
    await chatRef
        .collection('messages')
        .add(
          Message(
            id: '',
            senderUid: senderUid,
            text: text,
            sentAt: now,
          ).toJson(),
        );
    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': Timestamp.fromDate(now),
    });
  }
}
