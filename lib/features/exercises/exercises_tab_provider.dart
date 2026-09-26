import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set by other screens before pushing to /exercises, to open on a specific
/// tab instead of always defaulting to the first — e.g. the dashboard's
/// "Muscles Trained This Week" diagram jumps straight to Muscle Reports.
/// Mirrors pendingTrackingTabProvider's read-once-then-clear pattern.
final pendingExercisesTabProvider = StateProvider<int?>((ref) => null);
