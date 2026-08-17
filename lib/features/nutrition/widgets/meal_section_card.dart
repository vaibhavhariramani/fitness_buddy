import 'package:flutter/material.dart';

import '../../../models/meal_entry.dart';

class MealSectionCard extends StatelessWidget {
  final MealType type;
  final List<MealEntry> entries;
  final VoidCallback onAddFood;
  final void Function(MealEntry entry) onDelete;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(MealEntry entry)? onToggleSelect;

  const MealSectionCard({
    super.key,
    required this.type,
    required this.entries,
    required this.onAddFood,
    required this.onDelete,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final totalCalories = entries.fold<double>(0, (sum, e) => sum + e.calories);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type.label, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '${totalCalories.toStringAsFixed(0)} kcal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            for (final entry in entries)
              _EntryRow(
                entry: entry,
                onDelete: () => onDelete(entry),
                selectionMode: selectionMode,
                selected: selectedIds.contains(entry.id),
                onToggleSelect:
                    onToggleSelect == null
                        ? null
                        : () => onToggleSelect!(entry),
              ),
            if (!selectionMode)
              TextButton.icon(
                onPressed: onAddFood,
                icon: const Icon(Icons.add),
                label: const Text('Add food'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final MealEntry entry;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggleSelect;

  const _EntryRow({
    required this.entry,
    required this.onDelete,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final title = entry.foodName ?? 'Quick add';
    final subtitleParts = <String>[
      if (entry.servingDescription != null) entry.servingDescription!,
      'P ${entry.proteinG.toStringAsFixed(0)}g · C ${entry.carbG.toStringAsFixed(0)}g · F ${entry.fatG.toStringAsFixed(0)}g',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (selectionMode)
            Checkbox(value: selected, onChanged: (_) => onToggleSelect?.call()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  subtitleParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text('${entry.calories.toStringAsFixed(0)} kcal'),
          if (!selectionMode)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
