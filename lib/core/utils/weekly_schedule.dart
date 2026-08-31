/// Pure scheduling logic — kept out of widgets so it's directly testable.
/// A day's *resolved* plan is: this week's override if one exists for that
/// day, otherwise the permanent weekly routine's plan for that day.
library;

/// Resolves what plan (if any) applies to [isoWeekday] (1=Monday..7=Sunday)
/// for one specific week, given the permanent [routine] and this week's
/// [overrides]. Returns a WorkoutPlan id, or null for a rest day.
///
/// [overrides] takes precedence when present — even if its value is null
/// (an explicit "rest this week" override on a day the routine normally
/// trains). A day absent from [overrides] falls through to [routine].
String? resolveDayPlan({
  required Map<int, String?> routine,
  required Map<int, String?> overrides,
  required int isoWeekday,
}) {
  if (overrides.containsKey(isoWeekday)) return overrides[isoWeekday];
  return routine[isoWeekday];
}

/// The Monday (date-only, local time) that starts the calendar week
/// containing [date].
DateTime mondayOfWeek(DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  return dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
}
