import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/chat.dart';
import '../friends/friends_tab.dart';

final chatsProvider = StreamProvider.autoDispose<List<Chat>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatRepoProvider).watchChatsFor(uid);
});

class ChatsTab extends ConsumerWidget {
  const ChatsTab({super.key});

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    final myUid = ref.read(authStateProvider).valueOrNull?.uid;
    final myProfile = ref.read(userProfileProvider).valueOrNull;
    if (myUid == null || myProfile == null) return;

    final friendships = await ref.read(acceptedFriendsProvider.future);
    if (friendships.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a friend first to start chatting')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final otherUid = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Start a chat with'),
            children:
                friendships
                    .map((f) => f.otherUid(myUid))
                    .map(
                      (otherUid) => FutureBuilder(
                        future: ref.read(userRepoProvider).getProfile(otherUid),
                        builder:
                            (context, snapshot) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, otherUid),
                              child: Text(
                                snapshot.data?.displayName ?? otherUid,
                              ),
                            ),
                      ),
                    )
                    .toList(),
          ),
    );
    if (otherUid == null) return;

    final otherProfile = await ref.read(userRepoProvider).getProfile(otherUid);
    final chatId = await ref
        .read(chatRepoProvider)
        .getOrCreateDirectChat(
          myUid: myUid,
          myName: myProfile.displayName,
          otherUid: otherUid,
          otherName: otherProfile?.displayName ?? 'Friend',
        );
    if (context.mounted) context.push('/social/chat/$chatId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider);
    final myUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startChat(context, ref),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New chat'),
      ),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, i) {
              final chat = chats[i];
              final title =
                  chat.type == ChatType.group
                      ? (chat.groupName ?? 'Group chat')
                      : chat.participantNames.entries
                          .firstWhere(
                            (e) => e.key != myUid,
                            orElse: () => const MapEntry('', 'Chat'),
                          )
                          .value;
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    chat.type == ChatType.group ? Icons.group : Icons.person,
                  ),
                ),
                title: Text(title),
                subtitle: Text(chat.lastMessage ?? 'Say hello!'),
                trailing:
                    chat.lastMessageAt == null
                        ? null
                        : Text(DateFormat.Hm().format(chat.lastMessageAt!)),
                onTap: () => context.push('/social/chat/${chat.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
