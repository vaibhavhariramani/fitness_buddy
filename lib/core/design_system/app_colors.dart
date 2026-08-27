import 'package:flutter/material.dart';

/// Small, deliberate set of domain accent colors — used sparingly (an icon,
/// a ring, a thin bar) to give each data domain a consistent identity across
/// the app, never as large fills. The brand green (`ColorScheme.primary`)
/// stays the dominant color everywhere; these are accents layered on top of
/// the neutral canvas defined in `lib/app/theme.dart`, not a second palette.
class AppColors {
  const AppColors._();

  /// Training / workouts — reuses the brand green so "workout" reads as the
  /// app's core identity, not a separate category.
  static const workout = Color(0xFF2E7D32);

  /// Nutrition / fuel — warm amber, the conventional "calories/food" hue.
  static const nutrition = Color(0xFFE07A38);

  /// Recovery / body metrics (weight, rest) — calm blue.
  static const recovery = Color(0xFF3E7CB8);

  /// Achievement / analytics (PRs, streaks, trends) — a single violet accent
  /// reserved for moments worth celebrating, so it doesn't get diluted.
  static const achievement = Color(0xFF8B5CF6);
}
