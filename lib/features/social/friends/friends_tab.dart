import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/friendship.dart';
import '../../../models/user_profile.dart';
import '../widgets/story_avatar.dart';
import 'friend_progress_sheet.dart';

// Pending-request tiles show a directory-only lookup (uid/displayName/email)
// since we can't yet read the requester's full profile — Firestore rules
// only grant full-profile read once the friendship is accepted.

final acceptedFriendsProvider = StreamProvider.autoDispose<List<Friendship>>((
  ref,
) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendRepoProvider).watchAccepted(uid);
});

final incomingRequestsProvider = StreamProvider.autoDispose<List<Friendship>>((
  ref,
) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendRepoProvider).watchIncomingRequests(uid);
});

class FriendsTab extends ConsumerWidget {
  const FriendsTab({super.key});

  Future<void> _addFriend(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add friend by email'),
            content: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Friend\'s email'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(context, emailController.text.trim()),
                child: const Text('Send request'),
              ),
            ],
          ),
    );
    if (email == null || email.isEmpty) return;

    final myUid = ref.read(authStateProvider).valueOrNull?.uid;
    if (myUid == null) return;

    final otherUser = await ref
        .read(userRepoProvider)
        .findDirectoryEntryByEmail(email);
    if (otherUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with that email')),
        );
      }
      return;
    }
    if (otherUser.uid == myUid) return;

    await ref
        .read(friendRepoProvider)
        .sendRequest(myUid: myUid, otherUid: otherUser.uid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to ${otherUser.displayName}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(acceptedFriendsProvider);
    final requestsAsync = ref.watch(incomingRequestsProvider);
    final myUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFriend(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add friend'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (myUid != null) ...[
            _StoriesBar(myUid: myUid, friendsAsync: friendsAsync),
            const SizedBox(height: 16),
          ],
          requestsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (requests) {
              if (requests.isEmpty || myUid == null) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...requests.map(
                    (r) => _RequestTile(friendship: r, myUid: myUid),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          Text('Friends', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          friendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load: $e'),
            data: (friends) {
              if (friends.isEmpty || myUid == null) {
                return const Text('No friends yet. Add one by email above.');
              }
              return Column(
                children:
                    friends
                        .map((f) => _FriendTile(friendship: f, myUid: myUid))
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final Friendship friendship;
  final String myUid;

  const _RequestTile({required this.friendship, required this.myUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid = friendship.otherUid(myUid);
    return FutureBuilder<UserDirectoryEntry?>(
      future: ref.read(userRepoProvider).getDirectoryEntry(otherUid),
      builder: (context, snapshot) {
        final name = snapshot.data?.displayName ?? otherUid;
        return Card(
          child: ListTile(
            title: Text(name),
            subtitle: const Text('Wants to be your friend'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed:
                      () => ref
                          .read(friendRepoProvider)
                          .respondToRequest(
                            myUid: myUid,
                            otherUid: otherUid,
                            accept: true,
                          ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed:
                      () => ref
                          .read(friendRepoProvider)
                          .respondToRequest(
                            myUid: myUid,
                            otherUid: otherUid,
                            accept: false,
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal WhatsApp/Instagram-style status bar — "Your story" first, then
/// one ringed avatar per accepted friend who currently has an active story.
class _StoriesBar extends ConsumerWidget {
  final String myUid;
  final AsyncValue<List<Friendship>> friendsAsync;

  const _StoriesBar({required this.myUid, required this.friendsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myName =
        ref.watch(userProfileProvider).valueOrNull?.displayName ?? 'You';
    final friends = friendsAsync.valueOrNull ?? const [];

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StoryBarItem(uid: myUid, label: 'Your story', displayName: myName),
          for (final f in friends)
            _FriendStoryBarItem(otherUid: f.otherUid(myUid)),
        ],
      ),
    );
  }
}

class _FriendStoryBarItem extends ConsumerWidget {
  final String otherUid;

  const _FriendStoryBarItem({required this.otherUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<UserDirectoryEntry?>(
      future: ref.read(userRepoProvider).getDirectoryEntry(otherUid),
      builder: (context, snapshot) {
        final name = snapshot.data?.displayName;
        if (name == null) return const SizedBox.shrink();
        return _StoryBarItem(uid: otherUid, label: name, displayName: name);
      },
    );
  }
}

class _StoryBarItem extends StatelessWidget {
  final String uid;
  final String label;
  final String displayName;

  const _StoryBarItem({
    required this.uid,
    required this.label,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            StoryAvatar(uid: uid, displayName: displayName),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  final Friendship friendship;
  final String myUid;

  const _FriendTile({required this.friendship, required this.myUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid = friendship.otherUid(myUid);
    return FutureBuilder<UserProfile?>(
      future: ref.read(userRepoProvider).getProfile(otherUid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(profile?.displayName ?? '...'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  () => ref
                      .read(friendRepoProvider)
                      .removeFriend(myUid: myUid, otherUid: otherUid),
            ),
            onTap:
                profile == null
                    ? null
                    : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FriendProgressPage(friend: profile),
                      ),
                    ),
          ),
        );
      },
    );
  }
}
