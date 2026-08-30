import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'app/theme_mode_controller.dart';
import 'core/providers.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter's default release-mode ErrorWidget renders as a blank grey box
  // with no text — a widget that throws during build would look exactly
  // like "the screen is blank" with no way to tell why. Replace it with a
  // visible, recoverable error state, and log the underlying exception to
  // the browser console so it's actually diagnosable.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'Uncaught Flutter error',
      name: 'fitness_buddy',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  ErrorWidget.builder = (details) => _AppErrorWidget(details: details);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox('exercises_meta'),
    Hive.openBox('exercise_favorites'),
  ]);

  final prefs = await SharedPreferences.getInstance();
  final initialThemeMode = ThemeModeController.loadInitial(prefs);

  // An explicit container (rather than a plain `ProviderScope`) so the
  // notification tap handler below — which fires from outside the widget
  // tree — can read the router and navigate.
  final container = ProviderContainer(
    overrides: [
      themeModeProvider.overrideWith(
        (ref) => ThemeModeController(prefs, initialThemeMode),
      ),
    ],
  );

  final notificationService = container.read(notificationServiceProvider);
  await notificationService.init();
  notificationService.onNotificationTapped.listen((route) {
    container.read(routerProvider).go(route);
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FitnessBuddyApp(),
    ),
  );
}

/// Deliberately self-contained (own colors, no `Theme.of(context)`) since an
/// [ErrorWidget] can appear before a [MaterialApp]/[Theme] ancestor exists —
/// e.g. if the crash happens during the very first frame.
class _AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const _AppErrorWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 40),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong loading this screen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try reloading the page. If it keeps happening, this has been '
            'logged to the browser console.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF5C665F)),
          ),
        ],
      ),
    );
  }
}
