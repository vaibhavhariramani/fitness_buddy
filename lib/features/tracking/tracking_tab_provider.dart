import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set by other screens before pushing to /tracking, to open on a specific
/// tab (0=Weight, 1=Meals, 2=Workouts) instead of always defaulting to
/// Weight — e.g. the dashboard's "Today" nutrition card jumps straight to
/// the Meals tab. Consumed once by TrackingScreen, mirroring
/// pendingWorkoutPrefillProvider's read-once-then-clear pattern.
final pendingTrackingTabProvider = StateProvider<int?>((ref) => null);
