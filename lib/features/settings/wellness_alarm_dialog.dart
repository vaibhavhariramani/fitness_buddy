import 'package:flutter/material.dart';

import '../../models/wellness_reminder.dart';

/// Shown when a wellness reminder fires via NotificationService's Web
/// polling fallback (see its doc comment — native platforms fire a real OS
/// notification/alarm instead and never show this). Blocks back/dismiss for
/// alarm-mode reminders, matching how an actual alarm clock behaves; a
/// regular reminder can be tapped away.
class WellnessAlarmDialog extends StatelessWidget {
  final WellnessReminder reminder;
  final VoidCallback onStop;

  const WellnessAlarmDialog({
    super.key,
    required this.reminder,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !reminder.alarmMode,
      child: AlertDialog(
        icon: Icon(
          reminder.alarmMode ? Icons.alarm : Icons.notifications_active,
          size: 40,
        ),
        title: Text(reminder.name),
        content: Text(
          '${reminder.type.label} reminder — this tab is open, '
          "so this is standing in for the phone/desktop alarm that "
          "can't fire while the browser is closed.",
        ),
        actions: [FilledButton(onPressed: onStop, child: const Text('Stop'))],
      ),
    );
  }
}
