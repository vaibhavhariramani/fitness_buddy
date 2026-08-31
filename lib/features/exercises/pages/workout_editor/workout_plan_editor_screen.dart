import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../models/workout_plan.dart';
import '../../../tracking/workouts/pages/active_workout_page.dart';
import '../../providers/exercise_providers.dart';
import '../../widgets/exercise_picker_sheet.dart';
import '../../widgets/exercise_substitute_sheet.dart';
import '../../widgets/exercise_visual.dart';
import '../../widgets/planned_exercise_config_dialog.dart';

class WorkoutPlanEditorScreen extends ConsumerStatefulWidget {
  /// Null when creating a brand-new plan.
  final WorkoutPlan? plan;

  const WorkoutPlanEditorScreen({super.key, this.plan});

  @override
  ConsumerState<WorkoutPlanEditorScreen> createState() =>
      _WorkoutPlanEditorScreenState();
}

class _WorkoutPlanEditorScreenState
    extends ConsumerState<WorkoutPlanEditorScreen> {
  late final _nameController = TextEditingController(
    text: widget.plan?.name ?? '',
  );
  late List<PlannedExercise> _exercises = List.of(
    widget.plan?.exercises ?? const [],
  );
  bool _saving = false;

  bool get _isEditing => widget.plan != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final exercise = await showExercisePickerSheet(context);
    if (exercise == null) return;
    setState(() {
      _exercises = [
        ..._exercises,
        PlannedExercise(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          sets: 3,
          targetReps: 10,
        ),
      ];
    });
  }

  Future<void> _editExercise(int index) async {
    final updated = await showPlannedExerciseConfigDialog(
      context,
      _exercises[index],
    );
    if (updated == null) return;
    setState(() => _exercises = List.of(_exercises)..[index] = updated);
  }

  void _removeExercise(int index) {
    setState(() => _exercises = List.of(_exercises)..removeAt(index));
  }

  Future<void> _replaceExercise(int index) async {
    final current = ref.read(
      exerciseByIdProvider(_exercises[index].exerciseId),
    );
    if (current == null) return;
    final substitute = await showExerciseSubstituteSheet(context, current);
    if (substitute == null) return;
    final old = _exercises[index];
    setState(() {
      _exercises = List.of(_exercises)
        ..[index] = PlannedExercise(
          exerciseId: substitute.id,
          exerciseName: substitute.name,
          sets: old.sets,
          targetReps: old.targetReps,
          isTimed: old.isTimed,
          restSeconds: old.restSeconds,
        );
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      final updated = List.of(_exercises);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _exercises = updated;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Give your plan a name')));
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(workoutPlanRepoProvider);
      final now = DateTime.now();
      if (_isEditing) {
        await repo.update(
          uid,
          widget.plan!.copyWith(
            name: name,
            exercises: _exercises,
            updatedAt: now,
          ),
        );
      } else {
        await repo.create(
          uid,
          WorkoutPlan(
            id: '',
            name: name,
            exercises: _exercises,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete plan?'),
            content: Text(
              '"${widget.plan!.name}" will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref.read(workoutPlanRepoProvider).delete(uid, widget.plan!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _duplicate() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref.read(workoutPlanRepoProvider).duplicate(uid, widget.plan!);
    if (mounted) Navigator.pop(context);
  }

  void _startWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ActiveWorkoutPage(
              title: widget.plan!.name,
              seeds: [
                for (final p in _exercises)
                  SessionExerciseSeed(
                    exerciseId: p.exerciseId,
                    exerciseName: p.exerciseName,
                    targetSets: p.sets,
                    targetReps: p.targetReps,
                    isTimed: p.isTimed,
                    restSeconds: p.restSeconds,
                  ),
              ],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit plan' : 'New plan'),
        actions: [
          if (_isEditing && _exercises.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Start workout',
              onPressed: _startWorkout,
            ),
          if (_isEditing)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'duplicate') _duplicate();
                if (value == 'delete') _delete();
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
            ),
          IconButton(
            icon:
                _saving
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Plan name'),
            ),
          ),
          Expanded(
            child:
                _exercises.isEmpty
                    ? Center(
                      child: Text(
                        'No exercises yet — tap "Add exercise" to build your plan.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _exercises.length,
                      onReorder: _reorderExercises,
                      itemBuilder: (context, index) {
                        final planned = _exercises[index];
                        final exercise = ref.watch(
                          exerciseByIdProvider(planned.exerciseId),
                        );
                        return Card(
                          key: ValueKey('${planned.exerciseId}-$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: SizedBox(
                              width: 44,
                              height: 44,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    exercise == null
                                        ? const ColoredBox(
                                          color: Colors.transparent,
                                        )
                                        : ExerciseVisual(
                                          exerciseId: exercise.id,
                                          category: exercise.category,
                                          iconSize: 20,
                                        ),
                              ),
                            ),
                            title: Text(planned.exerciseName),
                            subtitle: Text(
                              planned.isTimed
                                  ? '${planned.sets} x ${planned.targetReps}s · ${planned.restSeconds}s rest'
                                  : '${planned.sets} x ${planned.targetReps} reps · ${planned.restSeconds}s rest',
                            ),
                            onTap: () => _editExercise(index),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'details') {
                                      context.push(
                                        '/exercises/${planned.exerciseId}',
                                      );
                                    } else if (value == 'replace') {
                                      _replaceExercise(index);
                                    }
                                  },
                                  itemBuilder:
                                      (context) => const [
                                        PopupMenuItem(
                                          value: 'details',
                                          child: Text('View details'),
                                        ),
                                        PopupMenuItem(
                                          value: 'replace',
                                          child: Text('Replace exercise'),
                                        ),
                                      ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeExercise(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Add exercise'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
