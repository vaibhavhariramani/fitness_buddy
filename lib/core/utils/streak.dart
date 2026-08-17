/// Lazy streak evaluation: the current streak is recomputed whenever the
/// user logs an activity, rather than via a scheduled server job. This keeps
/// the app on Firebase's free Spark plan (no Cloud Functions needed).
library;

class StreakResult {
  final int streakCount;
  final DateTime lastLogDate;

  const StreakResult({required this.streakCount, required this.lastLogDate});
}

class StreakCalculator {
  const StreakCalculator._();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Call this at the moment of any log write (weight/meal/workout).
  /// [previousStreak] and [previousLastLogDate] come from the user's stored
  /// profile; [today] defaults to DateTime.now() and is injectable for tests.
  static StreakResult onActivityLogged({
    required int previousStreak,
    required DateTime? previousLastLogDate,
    DateTime? today,
  }) {
    final now = _dateOnly(today ?? DateTime.now());

    if (previousLastLogDate == null) {
      return StreakResult(streakCount: 1, lastLogDate: now);
    }

    final last = _dateOnly(previousLastLogDate);
    final dayGap = now.difference(last).inDays;

    if (dayGap == 0) {
      // Already logged today; streak unchanged.
      return StreakResult(streakCount: previousStreak, lastLogDate: last);
    } else if (dayGap == 1) {
      return StreakResult(streakCount: previousStreak + 1, lastLogDate: now);
    } else {
      // Missed one or more days; streak resets.
      return StreakResult(streakCount: 1, lastLogDate: now);
    }
  }

  /// Call this when displaying the streak (e.g. dashboard load) without
  /// necessarily logging new activity, to show a reset if a day was missed.
  static int currentDisplayStreak({
    required int storedStreak,
    required DateTime? lastLogDate,
    DateTime? today,
  }) {
    if (lastLogDate == null) return 0;
    final now = _dateOnly(today ?? DateTime.now());
    final last = _dateOnly(lastLogDate);
    final dayGap = now.difference(last).inDays;
    if (dayGap > 1) return 0;
    return storedStreak;
  }
}
