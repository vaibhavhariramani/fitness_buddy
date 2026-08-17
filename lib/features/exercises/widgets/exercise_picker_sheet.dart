import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercise.dart';
import '../providers/exercise_providers.dart';
import 'exercise_visual.dart';

/// Modal bottom sheet for picking an exercise from the local catalog.
/// Returns the selected [Exercise], or null if dismissed.
Future<Exercise?> showExercisePickerSheet(BuildContext context) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _ExercisePickerSheet(),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add exercise',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search exercises',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged:
                      (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: exercisesAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (e, _) =>
                          Center(child: Text('Failed to load exercises: $e')),
                  data: (all) {
                    final filtered =
                        _query.isEmpty
                            ? all
                            : all
                                .where(
                                  (e) => e.name.toLowerCase().contains(_query),
                                )
                                .toList();
                    if (filtered.isEmpty) {
                      return const Center(child: Text('No exercises found.'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final exercise = filtered[i];
                        return ListTile(
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ExerciseVisual(
                                exerciseId: exercise.id,
                                category: exercise.category,
                                photoUrl: exercise.wgerImageUrl,
                                iconSize: 18,
                              ),
                            ),
                          ),
                          title: Text(exercise.name),
                          subtitle: Text(exercise.primaryMuscleNames),
                          onTap: () => Navigator.pop(context, exercise),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
