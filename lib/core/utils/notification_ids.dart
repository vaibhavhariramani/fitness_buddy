/// Deterministic per-day notification ids for wellness reminders, derived
/// from the reminder's Firestore doc id — so no extra id field needs to be
/// persisted, and cancelling a reminder is just "try all 7 possible day
/// slots" (cancelling an id that was never scheduled is a harmless no-op).
///
/// flutter_local_notifications needs a plain int id. Dart's String.hashCode
/// isn't guaranteed stable across platforms/SDK versions, which would make
/// cancellation unreliable long-term, so this uses a fixed, well-defined
/// FNV-1a 32-bit hash instead.
library;

int wellnessReminderBaseId(String reminderId) {
  var hash = 0x811c9dc5;
  for (final unit in reminderId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  // Offset well clear of the fixed meal/workout/nudge ids (9001-9104), and
  // stepped by 10 so each reminder has room for 7 day-slot ids (1-7) without
  // overlapping its neighbors.
  return 300000 + (hash % 100000) * 10;
}

/// [isoWeekday] is 1 (Monday) through 7 (Sunday), matching DateTime.weekday.
int wellnessNotificationId(String reminderId, int isoWeekday) {
  assert(isoWeekday >= 1 && isoWeekday <= 7);
  return wellnessReminderBaseId(reminderId) + isoWeekday;
}
