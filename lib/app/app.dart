import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import 'router.dart';
import 'theme.dart';
import 'theme_mode_controller.dart';

class FitnessBuddyApp extends ConsumerWidget {
  const FitnessBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // (Re)schedule local reminders whenever the profile first loads or its
    // reminder settings change — cheap no-op cancel-and-reschedule either
    // way, so it's simplest to just do it on every profile update.
    ref.listen(userProfileProvider, (previous, next) {
      final profile = next.valueOrNull;
      if (profile == null) return;
      final service = ref.read(notificationServiceProvider);
      service.requestPermission().then((_) {
        service.scheduleFromProfile(profile);
      });

      // FCM token registration involves a permission prompt and network
      // calls — only worth doing once per sign-in, not on every profile
      // field edit, so it's gated on the uid actually changing.
      if (previous?.valueOrNull?.uid != profile.uid) {
        ref.read(pushNotificationServiceProvider).initForUser(profile.uid);
      }
    });

    // Wellness reminders (medicine, yoga, meditation, ...) live in their own
    // collection rather than on the profile, so they get their own listener
    // — same cancel-and-reschedule-on-any-change strategy as meal/workout
    // reminders above, just scoped to that one reminder's notification ids
    // instead of the app-wide cancelAll().
    ref.listen(wellnessRemindersProvider, (previous, next) {
      final reminders = next.valueOrNull;
      if (reminders == null) return;
      ref
          .read(notificationServiceProvider)
          .scheduleWellnessReminders(reminders);
    });

    return MaterialApp.router(
      title: 'Fitness Buddy',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
