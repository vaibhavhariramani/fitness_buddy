/// A user-created reminder for a recurring wellness habit — taking
/// medicine, a yoga session, meditation, or anything else — distinct from
/// the fixed meal/workout reminder slots in [ReminderSettings] because
/// there can be any number of these, each with its own name and schedule.
enum WellnessReminderType {
  medicine,
  yoga,
  meditation,
  other;

  String get label => switch (this) {
    WellnessReminderType.medicine => 'Medicine',
    WellnessReminderType.yoga => 'Yoga',
    WellnessReminderType.meditation => 'Meditation',
    WellnessReminderType.other => 'Other',
  };
}

class WellnessReminder {
  final String id;
  final String name;
  final WellnessReminderType type;

  /// Local wall-clock time, stored as minutes since midnight (same
  /// convention as ReminderSettings) so it survives DST/Firestore
  /// round-trips cleanly.
  final int minutesSinceMidnight;

  /// ISO weekdays (1=Monday..7=Sunday) this reminder repeats on. All 7 means
  /// "every day".
  final List<int> repeatDays;

  final bool enabled;

  /// Id into core/utils/wellness_sounds.dart's registry.
  final String soundId;

  /// When true, schedules on Android's alarm-clock path (audible even in
  /// silent/Do Not Disturb, like a real alarm) rather than a regular
  /// notification. See NotificationService for the platform specifics and
  /// the exact-alarm permission this requires.
  final bool alarmMode;

  const WellnessReminder({
    required this.id,
    required this.name,
    required this.type,
    required this.minutesSinceMidnight,
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.enabled = true,
    this.soundId = 'default',
    this.alarmMode = true,
  });

  bool get isDaily => repeatDays.length == 7;

  WellnessReminder copyWith({
    String? name,
    WellnessReminderType? type,
    int? minutesSinceMidnight,
    List<int>? repeatDays,
    bool? enabled,
    String? soundId,
    bool? alarmMode,
  }) => WellnessReminder(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    minutesSinceMidnight: minutesSinceMidnight ?? this.minutesSinceMidnight,
    repeatDays: repeatDays ?? this.repeatDays,
    enabled: enabled ?? this.enabled,
    soundId: soundId ?? this.soundId,
    alarmMode: alarmMode ?? this.alarmMode,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'minutesSinceMidnight': minutesSinceMidnight,
    'repeatDays': repeatDays,
    'enabled': enabled,
    'soundId': soundId,
    'alarmMode': alarmMode,
  };

  factory WellnessReminder.fromJson(String id, Map<String, dynamic> json) =>
      WellnessReminder(
        id: id,
        name: json['name'] as String? ?? '',
        type: WellnessReminderType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => WellnessReminderType.other,
        ),
        minutesSinceMidnight: json['minutesSinceMidnight'] as int? ?? 8 * 60,
        repeatDays:
            (json['repeatDays'] as List?)?.map((d) => d as int).toList() ??
            const [1, 2, 3, 4, 5, 6, 7],
        enabled: json['enabled'] as bool? ?? true,
        soundId: json['soundId'] as String? ?? 'default',
        alarmMode: json['alarmMode'] as bool? ?? true,
      );
}
