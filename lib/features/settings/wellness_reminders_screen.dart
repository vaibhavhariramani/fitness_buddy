import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/providers.dart';
import '../../models/wellness_reminder.dart';
import '../../shared/widgets/app_card.dart';

const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

IconData _iconFor(WellnessReminderType type) => switch (type) {
  WellnessReminderType.medicine => Icons.medication_outlined,
  WellnessReminderType.yoga => Icons.self_improvement_outlined,
  WellnessReminderType.meditation => Icons.spa_outlined,
  WellnessReminderType.other => Icons.notifications_outlined,
};

String _repeatSummary(List<int> days) {
  if (days.length == 7) return 'Every day';
  if (days.isEmpty) return 'Never';
  final sorted = [...days]..sort();
  return sorted.map((d) => _dayNames[d - 1]).join(', ');
}

/// Medicine, yoga, meditation, or any other custom habit reminder — unlike
/// the fixed meal/workout slots in Settings, this is a plain CRUD list of
/// arbitrarily many user-created reminders, so it gets its own screen.
class WellnessRemindersScreen extends ConsumerWidget {
  const WellnessRemindersScreen({super.key});

  Future<void> _toggle(
    WidgetRef ref,
    WellnessReminder reminder,
    bool value,
  ) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref.read(wellnessReminderRepoProvider).update(uid, reminder.id, {
      'enabled': value,
    });
  }

  Future<void> _openEditor(
    BuildContext context, {
    required WellnessReminder? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReminderEditorSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders =
        ref.watch(wellnessRemindersProvider).valueOrNull ??
        const <WellnessReminder>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Wellness Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, existing: null),
        icon: const Icon(Icons.add),
        label: const Text('Add reminder'),
      ),
      body:
          reminders.isEmpty
              ? _EmptyState(onAdd: () => _openEditor(context, existing: null))
              : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text(
                    'Reminders for medicine, yoga, meditation, or anything '
                    'else you want a nudge for.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final reminder in reminders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ReminderCard(
                        reminder: reminder,
                        onTap: () => _openEditor(context, existing: reminder),
                        onToggle: (v) => _toggle(ref, reminder, v),
                      ),
                    ),
                ],
              ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.self_improvement_outlined,
              size: 48,
              color: scheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No wellness reminders yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add a reminder for medicine, yoga, meditation, or anything '
              'else.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final WellnessReminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay(
      hour: reminder.minutesSinceMidnight ~/ 60,
      minute: reminder.minutesSinceMidnight % 60,
    );
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.recovery.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconFor(reminder.type),
              color: AppColors.recovery,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${time.format(context)} · ${_repeatSummary(reminder.repeatDays)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: reminder.enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _ReminderEditorSheet extends ConsumerStatefulWidget {
  final WellnessReminder? existing;

  const _ReminderEditorSheet({required this.existing});

  @override
  ConsumerState<_ReminderEditorSheet> createState() =>
      _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends ConsumerState<_ReminderEditorSheet> {
  late final TextEditingController _nameController;
  late WellnessReminderType _type;
  late int _minutes;
  late Set<int> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _type = existing?.type ?? WellnessReminderType.medicine;
    _minutes = existing?.minutesSinceMidnight ?? 8 * 60;
    _days = (existing?.repeatDays ?? const [1, 2, 3, 4, 5, 6, 7]).toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
    );
    if (picked != null) {
      setState(() => _minutes = picked.hour * 60 + picked.minute);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_days.contains(day)) {
        _days.remove(day);
      } else {
        _days.add(day);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _days.isEmpty || _saving) return;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    final repo = ref.read(wellnessReminderRepoProvider);
    final existing = widget.existing;
    final sortedDays = _days.toList()..sort();
    try {
      if (existing == null) {
        await repo.add(
          uid,
          WellnessReminder(
            id: '',
            name: name,
            type: _type,
            minutesSinceMidnight: _minutes,
            repeatDays: sortedDays,
          ),
        );
      } else {
        await repo.update(uid, existing.id, {
          'name': name,
          'type': _type.name,
          'minutesSinceMidnight': _minutes,
          'repeatDays': sortedDays,
        });
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null || existing == null || _saving) return;

    setState(() => _saving = true);
    await ref.read(wellnessReminderRepoProvider).delete(uid, existing.id);
    await ref
        .read(notificationServiceProvider)
        .cancelWellnessReminder(existing.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60);
    final canSave = _nameController.text.trim().isNotEmpty && _days.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'New reminder' : 'Edit reminder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What is this for?',
                hintText: 'e.g. Vitamin D, Evening yoga',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final type in WellnessReminderType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time'),
              trailing: TextButton(
                onPressed: _pickTime,
                child: Text(time.format(context)),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Repeat', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var day = 1; day <= 7; day++)
                  _DayToggle(
                    label: _dayLabels[day - 1],
                    selected: _days.contains(day),
                    onTap: () => _toggleDay(day),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: _saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: (_saving || !canSave) ? null : _save,
                  child:
                      _saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
