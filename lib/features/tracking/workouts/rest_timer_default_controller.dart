import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _restTimerDefaultPrefsKey = 'rest_timer_default_enabled';

/// Whether a newly-added exercise starts with its rest timer on — a global
/// default only, never overriding a choice already made for a specific
/// exercise (see `_SessionExercise.restTimerEnabled` in ActiveWorkoutPage,
/// and the per-exercise "Rest timer" switch in its menu).
class RestTimerDefaultController extends StateNotifier<bool> {
  RestTimerDefaultController(this._prefs, bool initial) : super(initial);

  final SharedPreferences _prefs;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_restTimerDefaultPrefsKey, enabled);
  }

  static bool loadInitial(SharedPreferences prefs) {
    // Off by default — most users train straight through without needing a
    // prompt after every set; the per-exercise switch still lets anyone
    // turn it on for lifts where they actually want the countdown.
    return prefs.getBool(_restTimerDefaultPrefsKey) ?? false;
  }
}

/// Overridden in `main()` with the loaded [SharedPreferences] instance and
/// the value persisted from a previous session.
final restTimerDefaultProvider =
    StateNotifierProvider<RestTimerDefaultController, bool>((ref) {
      throw UnimplementedError(
        'restTimerDefaultProvider must be overridden in main()',
      );
    });
