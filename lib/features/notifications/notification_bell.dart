import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../models/app_notification.dart';

/// Bell icon with an unread-count badge; tapping it opens an anchored panel
/// listing recent notifications, each of which navigates to its target route
/// and marks itself read on tap. A short system sound plays whenever the
/// unread count increases while the app is open.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final _menuController = MenuController();
  int? _lastUnreadCount;

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    ref.listen(unreadNotificationCountProvider, (previous, next) {
      final count = next.valueOrNull;
      if (count == null) return;
      if (_lastUnreadCount != null && count > _lastUnreadCount!) {
        // Best-effort — some platforms (notably web without user gesture)
        // may silently ignore this rather than play anything.
        try {
          SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
      _lastUnreadCount = count;
    });

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(-320, 8),
      menuChildren: [_NotificationPanel(onClose: _menuController.close)],
      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

class _NotificationPanel extends ConsumerWidget {
  final VoidCallback onClose;

  const _NotificationPanel({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications =
        ref.watch(notificationsProvider).valueOrNull ?? const [];

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (notifications.any((n) => !n.read))
                    TextButton(
                      onPressed: () {
                        final uid =
                            ref.read(authStateProvider).valueOrNull?.uid;
                        if (uid != null) {
                          ref.read(notificationRepoProvider).markAllRead(uid);
                        }
                      },
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  notifications.isEmpty
                      ? Center(
                        child: Text(
                          'No notifications yet',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                      : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _NotificationTile(
                            notification: notification,
                            onTap: () {
                              onClose();
                              final uid =
                                  ref.read(authStateProvider).valueOrNull?.uid;
                              if (uid != null && !notification.read) {
                                ref
                                    .read(notificationRepoProvider)
                                    .markRead(uid, notification.id);
                              }
                              context.go(notification.route);
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  static String _relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        color:
            notification.read
                ? null
                : scheme.primaryContainer.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              backgroundImage:
                  notification.actorPhotoUrl != null
                      ? NetworkImage(notification.actorPhotoUrl!)
                      : null,
              child:
                  notification.actorPhotoUrl == null
                      ? Text(
                        notification.actorName.isNotEmpty
                            ? notification.actorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relative(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
