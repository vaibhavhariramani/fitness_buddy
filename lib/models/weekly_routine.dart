/// The user's permanent weekly training template — e.g. "Monday is Push Day,
/// Tuesday is rest, Wednesday is Pull Day...". Changing this affects every
/// future week. A single "this week I moved Tuesday to Thursday" swap should
/// NOT touch this — see [WeekSchedule] for that.
class WeeklyRoutine {
  /// ISO weekday (1=Monday..7=Sunday) -> WorkoutPlan id, or null for a rest
  /// day. A weekday with no entry at all is also treated as rest.
  final Map<int, String?> dayPlanIds;

  const WeeklyRoutine({this.dayPlanIds = const {}});

  String? planForDay(int isoWeekday) => dayPlanIds[isoWeekday];

  WeeklyRoutine withDay(int isoWeekday, String? planId) {
    final next = Map<int, String?>.from(dayPlanIds);
    if (planId == null) {
      next[isoWeekday] = null;
    } else {
      next[isoWeekday] = planId;
    }
    return WeeklyRoutine(dayPlanIds: next);
  }

  Map<String, dynamic> toJson() => {
    'days': {
      for (final entry in dayPlanIds.entries) entry.key.toString(): entry.value,
    },
  };

  factory WeeklyRoutine.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeeklyRoutine();
    final rawDays = json['days'];
    if (rawDays is! Map) return const WeeklyRoutine();
    final days = <int, String?>{};
    for (final entry in rawDays.entries) {
      final weekday = int.tryParse(entry.key.toString());
      if (weekday == null || weekday < 1 || weekday > 7) continue;
      days[weekday] = entry.value as String?;
    }
    return WeeklyRoutine(dayPlanIds: days);
  }
}
