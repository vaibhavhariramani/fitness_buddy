import 'package:flutter/widgets.dart';

/// Corner-radius scale. Matches the values already baked into
/// `lib/app/theme.dart`'s CardTheme/InputDecorationTheme/BottomSheetTheme —
/// exposed here as named constants so bespoke widgets (that can't just rely
/// on a Theme default) stay in step with the themed ones instead of drifting
/// to their own one-off numbers.
class AppRadius {
  const AppRadius._();

  /// Chips, tags, small compact controls.
  static const compact = 10.0;

  /// Inputs, secondary surfaces.
  static const input = 14.0;

  /// Standard cards.
  static const card = 20.0;

  /// Hero surfaces, sheets, dialogs, modals.
  static const sheet = 24.0;

  static BorderRadius get compactRadius => BorderRadius.circular(compact);
  static BorderRadius get inputRadius => BorderRadius.circular(input);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get sheetRadius => BorderRadius.circular(sheet);
}
