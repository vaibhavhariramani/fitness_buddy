import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModePrefsKey = 'theme_mode';

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs, ThemeMode initial) : super(initial);

  final SharedPreferences _prefs;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_themeModePrefsKey, mode.name);
  }

  static ThemeMode loadInitial(SharedPreferences prefs) {
    final stored = prefs.getString(_themeModePrefsKey);
    // Dark by default on a fresh install (no stored preference yet) — once
    // the user picks a mode via the toggle, that explicit choice always wins.
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.dark,
    );
  }
}

/// Overridden in `main()` with the loaded [SharedPreferences] instance and
/// the theme mode persisted from a previous session.
final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    throw UnimplementedError('themeModeProvider must be overridden in main()');
  },
);
