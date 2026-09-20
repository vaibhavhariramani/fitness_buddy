import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/chat.dart';
import '../../../models/message.dart';
import 'chats_tab.dart' show chatsProvider;

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, chatId) {
      return ref.watch(chatRepoProvider).watchMessages(chatId);
    });

/// Derived from the same stream [chatsProvider] already keeps open for the
/// chat list, rather than a second Firestore listener for one document.
final chatByIdProvider = Provider.autoDispose.family<Chat?, String>((
  ref,
  chatId,
) {
  final chats = ref.watch(chatsProvider).valueOrNull ?? const [];
  for (final chat in chats) {
    if (chat.id == chatId) return chat;
  }
  return null;
});

class ChatThreadScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatThreadScreen({required this.chatId, super.key});

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    _textController.clear();
    await ref
        .read(chatRepoProvider)
        .sendMessage(chatId: widget.chatId, senderUid: uid, text: text);
  }

  Future<void> _report(String otherUid, String otherName) async {
    final reasons = [
      'Harassment or bullying',
      'Spam',
      'Inappropriate content',
      'Something else',
    ];
    final reason = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('Report $otherName'),
            children:
                reasons
                    .map(
                      (r) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, r),
                        child: Text(r),
                      ),
                    )
                    .toList(),
          ),
    );
    if (reason == null) return;

    final myUid = ref.read(authStateProvider).valueOrNull?.uid;
    if (myUid == null) return;
    await ref
        .read(reportRepoProvider)
        .submit(
          reporterUid: myUid,
          reportedUid: otherUid,
          reportedName: otherName,
          reason: reason,
          chatId: widget.chatId,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reported $otherName. Thanks for flagging.')),
      );
    }
  }

  Future<void> _block(String otherUid, String otherName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Block $otherName?'),
            content: Text(
              'You\'ll stop being friends and $otherName won\'t be able to '
              'message you again. This can\'t be undone from here.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Block'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    final myUid = ref.read(authStateProvider).valueOrNull?.uid;
    if (myUid == null) return;
    await ref
        .read(friendRepoProvider)
        .removeFriend(myUid: myUid, otherUid: otherUid);
    await ref
        .read(reportRepoProvider)
        .submit(
          reporterUid: myUid,
          reportedUid: otherUid,
          reportedName: otherName,
          reason: 'Blocked',
          chatId: widget.chatId,
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$otherName is blocked.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final myUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final chat = ref.watch(chatByIdProvider(widget.chatId));

    final isDirect = chat != null && chat.type == ChatType.direct;
    final otherUid =
        isDirect
            ? chat.participantUids.firstWhere(
              (uid) => uid != myUid,
              orElse: () => '',
            )
            : '';
    final title =
        chat == null
            ? 'Chat'
            : chat.type == ChatType.group
            ? (chat.groupName ?? 'Group chat')
            : (chat.participantNames[otherUid] ?? 'Chat');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isDirect && otherUid.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'report') {
                  _report(otherUid, title);
                } else if (action == 'block') {
                  _block(otherUid, title);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: ListTile(
                        leading: Icon(Icons.flag_outlined),
                        title: Text('Report'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: ListTile(
                        leading: Icon(
                          Icons.block,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          'Block',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
            )
          else
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'report') _report('', title);
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: ListTile(
                        leading: Icon(Icons.flag_outlined),
                        title: Text('Report this chat'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hello!'),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final message = messages[messages.length - 1 - i];
                    final isMine = message.senderUid == myUid;
                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color:
                              isMine
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                  : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.text),
                            Text(
                              DateFormat.Hm().format(message.sentAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
