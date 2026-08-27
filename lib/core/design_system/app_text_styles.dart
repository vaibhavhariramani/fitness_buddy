import 'package:flutter/material.dart';

/// Numeric/stat typography — for the big metrics (weight, calories, PR
/// weights, streak counts) that anchor the dashboard and progress screens.
/// Kept separate from [TextTheme] because Material's type scale has no
/// "stat" slot, and these need tabular figures (fixed-width digits) so a
/// value doesn't visually reflow as it changes.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle statDisplay(Color color) => TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    height: 1.0,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle statLarge(Color color) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.05,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle statMedium(Color color) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.1,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle statSmall(Color color) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.1,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
