/// Truncates [d] to just its calendar date (local time, midnight) — the
/// standard way this app compares "same day" across logs, streaks, and
/// weekly aggregations.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
