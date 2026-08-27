import 'package:flutter/services.dart';

/// Thin, semantic wrapper around [HapticFeedback] — named for *why* a haptic
/// fires rather than which raw platform pattern it maps to, so call sites
/// stay readable and the mapping can be tuned in one place. No new
/// dependency: `flutter/services.dart` is already part of the SDK.
class AppHaptics {
  const AppHaptics._();

  /// A set/rep marked complete, a toggle flipped.
  static void tap() => HapticFeedback.selectionClick();

  /// A meaningful confirmation — saved, added, exercise added to a workout.
  static void success() => HapticFeedback.lightImpact();

  /// A workout finished, a new personal record — the biggest moments.
  static void celebrate() => HapticFeedback.mediumImpact();

  /// A destructive or blocking action (validation error, delete).
  static void warn() => HapticFeedback.heavyImpact();
}
