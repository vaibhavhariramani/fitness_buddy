import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/theme_mode_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox('exercises_meta'),
    Hive.openBox('exercise_favorites'),
  ]);

  final prefs = await SharedPreferences.getInstance();
  final initialThemeMode = ThemeModeController.loadInitial(prefs);

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => ThemeModeController(prefs, initialThemeMode),
        ),
      ],
      child: const FitnessBuddyApp(),
    ),
  );
}
