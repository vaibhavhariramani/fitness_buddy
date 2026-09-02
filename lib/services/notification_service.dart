import 'dart:async';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/notification_ids.dart';
import '../core/utils/wellness_sounds.dart';
import '../models/user_profile.dart';
import '../models/wellness_reminder.dart';

/// Fixed notification ids so re-scheduling always replaces the same slots
/// instead of accumulating duplicates.
class _ReminderIds {
  static const breakfast = 9001;
  static const lunch = 9002;
  static const workout = 9003;
  static const dinner = 9004;
  static const junkNudgeSlots = [9101, 9102];
}

/// Rotating, Zomato-ad-style copy for the "don't eat junk" nudges — picked
/// at random each time reminders are (re)scheduled so it doesn't feel like
/// the same nag every day.
const _junkFoodNudges = [
  'That 11pm fries craving is just boredom wearing a tasty disguise. Drink water first 💧',
  "Your future self called — they'd rather you had the fruit bowl than the fries.",
  'Snack alert: the vending machine is not a food group. Log a real meal instead 🥗',
  "Zero notifications from your abs today. They'd like you to skip the chips.",
  'Plot twist: the healthy snack is right there and it takes the same 10 seconds.',
  "This is your friendly reminder that junk food doesn't log itself into your goals.",
];

/// Local, on-device meal/workout reminders — no backend involved. Each
/// reminder repeats daily at a fixed wall-clock time via
/// [DateTimeComponents.time], which `zonedSchedule` re-resolves against the
/// device's current timezone on every fire (so DST shifts don't drift it).
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _tappedRouteController = StreamController<String>.broadcast();

  /// Emits the target route (e.g. `/tracking`) whenever the user taps a
  /// notification while the app is running.
  Stream<String> get onNotificationTapped => _tappedRouteController.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimeZone));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null) {
      // Defer until the first listener (the router) is attached.
      scheduleMicrotask(() => _tappedRouteController.add(launchPayload));
    }
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) _tappedRouteController.add(payload);
  }

  /// Lets other notification sources (e.g. a tapped FCM push) feed into the
  /// same tap-routing stream the router listens to, so there's one place
  /// that turns "a notification was tapped" into navigation.
  void notifyExternalTap(String route) => _tappedRouteController.add(route);

  /// Surfaces a message that arrived while the app was in the foreground —
  /// FCM doesn't auto-display a banner for foreground messages on either
  /// platform, so this uses the same local-notification channel reminders
  /// use, keeping tap handling consistent.
  Future<void> showRemote({
    required String title,
    required String body,
    required String route,
  }) {
    return _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      _socialDetails,
      payload: route,
    );
  }

  Future<bool> requestPermission() async {
    final androidGranted =
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        true;
    final iosGranted =
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    return androidGranted && iosGranted;
  }

  static const _mealChannel = AndroidNotificationDetails(
    'meal_workout_reminders',
    'Meal & workout reminders',
    channelDescription: 'Daily reminders to log meals and workouts',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _nudgeChannel = AndroidNotificationDetails(
    'junk_food_nudges',
    'Snack nudges',
    channelDescription: 'Playful reminders to skip the junk food',
    importance: Importance.defaultImportance,
  );

  static const _socialChannel = AndroidNotificationDetails(
    'friend_activity',
    'Friend activity',
    channelDescription: "Pings when a friend logs a meal, weight, or workout",
    importance: Importance.high,
    priority: Priority.high,
  );

  NotificationDetails get _mealDetails => const NotificationDetails(
    android: _mealChannel,
    iOS: DarwinNotificationDetails(),
  );

  NotificationDetails get _nudgeDetails => const NotificationDetails(
    android: _nudgeChannel,
    iOS: DarwinNotificationDetails(),
  );

  NotificationDetails get _socialDetails => const NotificationDetails(
    android: _socialChannel,
    iOS: DarwinNotificationDetails(),
  );

  /// Unlike the other fixed channels above, wellness reminders need a
  /// distinct channel per sound/alarm-mode combination — on Android, a
  /// channel's sound and audio attributes are locked in the first time it's
  /// created and silently ignored on every later call with the same
  /// channel id, so reusing one shared channel would mean only the first
  /// reminder's sound/alarm setting ever actually took effect.
  NotificationDetails _wellnessDetailsFor(WellnessSound sound, bool alarmMode) {
    final channelId = 'wellness_${sound.id}_${alarmMode ? 'alarm' : 'notify'}';
    final channelName =
        alarmMode
            ? 'Wellness alarms — ${sound.label}'
            : 'Wellness reminders — ${sound.label}';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription:
            'Medicine, yoga, meditation, and other custom reminders you set',
        importance: alarmMode ? Importance.max : Importance.high,
        priority: alarmMode ? Priority.max : Priority.high,
        playSound: true,
        sound:
            sound.androidRawResource == null
                ? null
                : RawResourceAndroidNotificationSound(
                  sound.androidRawResource!,
                ),
        audioAttributesUsage:
            alarmMode
                ? AudioAttributesUsage.alarm
                : AudioAttributesUsage.notification,
        category: alarmMode ? AndroidNotificationCategory.alarm : null,
        fullScreenIntent: alarmMode,
      ),
      iOS: DarwinNotificationDetails(sound: sound.iosSoundFile),
    );
  }

  /// Cancels and re-schedules every reminder from scratch based on the
  /// current profile — safe to call any time settings change.
  Future<void> scheduleFromProfile(UserProfile profile) async {
    await cancelAll();
    final reminders = profile.reminders;
    if (!reminders.enabled) return;

    await _scheduleDaily(
      id: _ReminderIds.breakfast,
      minutesSinceMidnight: reminders.breakfastMinutes,
      title: 'Breakfast check-in 🍳',
      body: "Log what you had for breakfast — it only takes a few seconds.",
      route: '/tracking',
    );
    await _scheduleDaily(
      id: _ReminderIds.lunch,
      minutesSinceMidnight: reminders.lunchMinutes,
      title: 'Lunch time 🍱',
      body: 'Log your lunch to keep today\'s macros on track.',
      route: '/tracking',
    );
    await _scheduleDaily(
      id: _ReminderIds.workout,
      minutesSinceMidnight: reminders.workoutMinutes,
      title: 'Workout window 💪',
      body: "Ready to log today's session? A quick set beats no sets.",
      route: '/tracking',
    );
    await _scheduleDaily(
      id: _ReminderIds.dinner,
      minutesSinceMidnight: reminders.dinnerMinutes,
      title: 'Dinner check-in 🍽️',
      body: "Don't forget to log dinner before the day resets.",
      route: '/tracking',
    );

    if (reminders.junkFoodNudgesEnabled) {
      await _scheduleJunkFoodNudges(reminders);
    }
  }

  /// Two nudges a day, offset from meal times so they read as an
  /// independent "don't snack" ping rather than a meal reminder — picked at
  /// fixed slots (mid-morning, mid-afternoon) with a randomly chosen message
  /// each time reminders are (re)scheduled.
  Future<void> _scheduleJunkFoodNudges(ReminderSettings reminders) async {
    final rand = Random();
    final slotMinutes = [
      (reminders.breakfastMinutes + reminders.lunchMinutes) ~/ 2,
      (reminders.workoutMinutes + reminders.dinnerMinutes) ~/ 2,
    ];
    for (var i = 0; i < _ReminderIds.junkNudgeSlots.length; i++) {
      await _scheduleDaily(
        id: _ReminderIds.junkNudgeSlots[i],
        minutesSinceMidnight: slotMinutes[i],
        title: 'Snack check 👀',
        body: _junkFoodNudges[rand.nextInt(_junkFoodNudges.length)],
        route: '/tracking',
        details: _nudgeDetails,
      );
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int minutesSinceMidnight,
    required String title,
    required String body,
    required String route,
    NotificationDetails? details,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesSinceMidnight ~/ 60,
      minutesSinceMidnight % 60,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details ?? _mealDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: route,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancel(_ReminderIds.breakfast);
    await _plugin.cancel(_ReminderIds.lunch);
    await _plugin.cancel(_ReminderIds.workout);
    await _plugin.cancel(_ReminderIds.dinner);
    for (final id in _ReminderIds.junkNudgeSlots) {
      await _plugin.cancel(id);
    }
  }

  /// Cancels and re-schedules every wellness reminder from scratch — cheap
  /// enough to call on every change to the list, same strategy as
  /// [scheduleFromProfile]. Unlike the fixed meal/workout slots, these are
  /// unboundedly many and user-edited individually, so each reminder's
  /// notification ids are derived from its own doc id (see
  /// core/utils/notification_ids.dart) rather than a hand-enumerated
  /// constant, and only that reminder's ids get cancelled/rescheduled.
  Future<void> scheduleWellnessReminders(
    List<WellnessReminder> reminders,
  ) async {
    // Android 12+ gates AndroidScheduleMode.alarmClock behind this
    // permission, granted via a system Settings screen rather than an
    // in-app dialog — request it once up front if any reminder needs it,
    // rather than per-reminder.
    if (reminders.any((r) => r.enabled && r.alarmMode)) {
      await _requestExactAlarmPermission();
    }

    for (final reminder in reminders) {
      await cancelWellnessReminder(reminder.id);
      if (!reminder.enabled) continue;
      final details = _wellnessDetailsFor(
        wellnessSoundById(reminder.soundId),
        reminder.alarmMode,
      );
      for (final day in reminder.repeatDays) {
        await _scheduleWeekly(
          id: wellnessNotificationId(reminder.id, day),
          isoWeekday: day,
          minutesSinceMidnight: reminder.minutesSinceMidnight,
          title: '${reminder.type.label} reminder',
          body: reminder.name,
          route: '/wellness-reminders',
          details: details,
          alarmMode: reminder.alarmMode,
        );
      }
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  /// Cancels all 7 possible day-slot ids for one reminder — cancelling an id
  /// that was never scheduled (e.g. a day not in repeatDays) is a no-op, so
  /// this doesn't need to know which days were actually in use.
  Future<void> cancelWellnessReminder(String reminderId) async {
    for (var day = 1; day <= 7; day++) {
      await _plugin.cancel(wellnessNotificationId(reminderId, day));
    }
  }

  /// Like [_scheduleDaily] but repeats weekly on one specific weekday
  /// instead of every day, via [DateTimeComponents.dayOfWeekAndTime].
  Future<void> _scheduleWeekly({
    required int id,
    required int isoWeekday,
    required int minutesSinceMidnight,
    required String title,
    required String body,
    required String route,
    required NotificationDetails details,
    bool alarmMode = false,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesSinceMidnight ~/ 60,
      minutesSinceMidnight % 60,
    );
    // DateTime.weekday is already 1 (Monday)..7 (Sunday), matching isoWeekday.
    while (scheduled.weekday != isoWeekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: route,
    );

    if (!alarmMode) {
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      return;
    }
    try {
      await schedule(AndroidScheduleMode.alarmClock);
    } catch (_) {
      // Exact-alarm permission wasn't granted (or the platform doesn't
      // support it) — still show the reminder rather than dropping it
      // silently, just without the alarm-clock guarantees.
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  void dispose() {
    _tappedRouteController.close();
  }
}
