import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/exercise_providers.dart';

class CategoryChipRow extends ConsumerWidget {
  const CategoryChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final filter = ref.watch(exerciseLibraryFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('All'),
              selected: filter.category == null,
              onSelected:
                  (_) => ref
                      .read(exerciseLibraryFilterProvider.notifier)
                      .setCategory(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(category),
                selected: filter.category == category,
                onSelected:
                    (selected) => ref
                        .read(exerciseLibraryFilterProvider.notifier)
                        .setCategory(selected ? category : null),
              ),
            ),
        ],
      ),
    );
  }
}
