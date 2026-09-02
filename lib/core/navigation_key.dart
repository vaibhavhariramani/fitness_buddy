import 'package:flutter/widgets.dart';

/// Lets non-widget code (NotificationService's web reminder alerts, which
/// fire from a plain Dart Timer with no BuildContext of their own) show a
/// dialog over whatever's currently on screen. Kept in its own file with no
/// other imports so both router.dart and notification_service.dart can
/// depend on it without creating an import cycle between them.
final rootNavigatorKey = GlobalKey<NavigatorState>();
