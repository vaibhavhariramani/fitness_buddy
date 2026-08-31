import 'package:cloud_firestore/cloud_firestore.dart';

/// A one-off override for a single day within one specific calendar week —
/// "skip this Tuesday" or "swap Thursday for the Push Day plan just this
/// week" — without touching the permanent [WeeklyRoutine].
class WeekSchedule {
  /// The Monday that starts this week, date-only.
  final DateTime weekStart;

  /// ISO weekday (1=Monday..7=Sunday) -> WorkoutPlan id, or null meaning
  /// "forced rest this week". A weekday with NO entry here falls back to
  /// the permanent routine for that day — see `resolveDayPlan`.
  final Map<int, String?> overrides;

  const WeekSchedule({required this.weekStart, this.overrides = const {}});

  bool get isEmpty => overrides.isEmpty;

  WeekSchedule withOverride(int isoWeekday, String? planId) {
    final next = Map<int, String?>.from(overrides);
    next[isoWeekday] = planId;
    return WeekSchedule(weekStart: weekStart, overrides: next);
  }

  WeekSchedule withoutOverride(int isoWeekday) {
    final next = Map<int, String?>.from(overrides)..remove(isoWeekday);
    return WeekSchedule(weekStart: weekStart, overrides: next);
  }

  Map<String, dynamic> toJson() => {
    'weekStart': Timestamp.fromDate(weekStart),
    'overrides': {
      for (final entry in overrides.entries) entry.key.toString(): entry.value,
    },
  };

  factory WeekSchedule.fromJson(
    DateTime weekStart,
    Map<String, dynamic>? json,
  ) {
    if (json == null) return WeekSchedule(weekStart: weekStart);
    final rawOverrides = json['overrides'];
    final overrides = <int, String?>{};
    if (rawOverrides is Map) {
      for (final entry in rawOverrides.entries) {
        final weekday = int.tryParse(entry.key.toString());
        if (weekday == null || weekday < 1 || weekday > 7) continue;
        overrides[weekday] = entry.value as String?;
      }
    }
    return WeekSchedule(weekStart: weekStart, overrides: overrides);
  }
}
