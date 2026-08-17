import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/exercise_providers.dart';

class EquipmentFilterSheet extends ConsumerWidget {
  const EquipmentFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipment = ref.watch(equipmentListProvider);
    final filter = ref.watch(exerciseLibraryFilterProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter by equipment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  RadioListTile<String?>(
                    title: const Text('Any equipment'),
                    value: null,
                    groupValue: filter.equipment,
                    onChanged:
                        (v) => ref
                            .read(exerciseLibraryFilterProvider.notifier)
                            .setEquipment(v),
                  ),
                  for (final e in equipment)
                    RadioListTile<String?>(
                      title: Text(e),
                      value: e,
                      groupValue: filter.equipment,
                      onChanged:
                          (v) => ref
                              .read(exerciseLibraryFilterProvider.notifier)
                              .setEquipment(v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
