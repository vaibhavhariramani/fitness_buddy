import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'notification_service.dart';
import 'repositories/user_repo.dart';

/// Registered via `FirebaseMessaging.onBackgroundMessage` — must be a
/// top-level (or static) function since it runs in its own isolate. Left
/// empty on purpose: the OS already renders the system-tray notification for
/// background/terminated messages, so there's nothing else to do here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Wraps `firebase_messaging` for friend-activity push: registers this
/// device's token, keeps it fresh, and routes taps through the same
/// [NotificationService] tap stream local reminders use.
///
/// On iOS this silently does nothing if the app isn't signed with an Apple
/// Developer Program membership (APNs requires the Push Notifications
/// entitlement, which a free personal team can't add) — `getToken()` throws
/// in that case, which we swallow rather than let crash app startup.
class PushNotificationService {
  final NotificationService _localNotifications;
  final UserRepo _userRepo;

  StreamSubscription<String>? _tokenRefreshSub;
  String? _currentToken;

  PushNotificationService({
    required NotificationService localNotifications,
    required UserRepo userRepo,
  }) : _localNotifications = localNotifications,
       _userRepo = userRepo;

  Future<void> initForUser(String uid) async {
    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _userRepo.saveFcmToken(uid, token);
      }
    } catch (_) {
      // No APNs entitlement / permission denied — see class doc.
    }

    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      await _userRepo.updateProfile(uid, {'timezone': tz});
    } catch (_) {
      // Best-effort — the daily-summary story just won't fire for this user
      // until it succeeds on a later launch.
    }

    unawaited(_tokenRefreshSub?.cancel());
    _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _userRepo.saveFcmToken(uid, newToken);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleOpenedMessage(initialMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.showRemote(
      title: notification.title ?? 'Fitness Buddy',
      body: notification.body ?? '',
      route: message.data['route'] as String? ?? '/social',
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _localNotifications.notifyExternalTap(
      message.data['route'] as String? ?? '/social',
    );
  }

  /// Best-effort — called with the still-authenticated uid just before
  /// sign-out so a shared device stops receiving this user's pushes.
  Future<void> clearForSignOut(String uid) async {
    final token = _currentToken;
    if (token != null) {
      await _userRepo.removeFcmToken(uid, token);
    }
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _currentToken = null;
  }
}
