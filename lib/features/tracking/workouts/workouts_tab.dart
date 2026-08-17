import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/workout_entry.dart';
import '../../exercises/models/exercise.dart';
import '../../exercises/providers/exercise_providers.dart';
import '../../exercises/widgets/add_to_workout_dialog.dart'
    show nearestMuscleGroup;
import 'pages/active_workout_page.dart';
import 'workout_prefill_provider.dart';

final workoutHistoryProvider = StreamProvider.autoDispose<List<WorkoutEntry>>((
  ref,
) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(workoutRepoProvider).watchAll(uid);
});

class WorkoutsTab extends ConsumerStatefulWidget {
  const WorkoutsTab({super.key});

  @override
  ConsumerState<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends ConsumerState<WorkoutsTab> {
  bool _prefillHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefill = ref.read(pendingWorkoutPrefillProvider);
    if (prefill != null && !_prefillHandled) {
      _prefillHandled = true;
      ref.read(pendingWorkoutPrefillProvider.notifier).state = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder:
              (context) => LogWorkoutSheet(
                prefillName: prefill.name,
                prefillMuscleGroup: prefill.muscleGroup,
              ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          TextButton.icon(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const ActiveWorkoutPage(title: 'Workout'),
                  ),
                ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const LogWorkoutSheet(),
            ),
        icon: const Icon(Icons.add),
        label: const Text('Log workout'),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (workouts) {
          if (workouts.isEmpty) {
            return const Center(child: Text('No workouts logged yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, i) {
              final workout = workouts[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMd().format(workout.date),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      for (final exercise in workout.exercises)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${exercise.name} (${exercise.muscleGroup}) — '
                                  '${exercise.sets.map((s) => '${s.reps}x${s.weightKg.toStringAsFixed(0)}kg').join(', ')}',
                                ),
                              ),
                              if (exercise.isPr)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Chip(
                                    label: Text('PR'),
                                    avatar: Icon(Icons.emoji_events, size: 16),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DraftSet {
  int reps = 8;
  double weightKg = 20;
}

class _DraftExercise {
  String name = '';
  String muscleGroup = 'Chest';
  String? exerciseId;
  List<_DraftSet> sets = [_DraftSet()];
}

const muscleGroups = [
  'Chest',
  'Back',
  'Legs',
  'Shoulders',
  'Arms',
  'Core',
  'Full body',
];

class LogWorkoutSheet extends ConsumerStatefulWidget {
  final String? prefillName;
  final String? prefillMuscleGroup;

  const LogWorkoutSheet({super.key, this.prefillName, this.prefillMuscleGroup});

  @override
  ConsumerState<LogWorkoutSheet> createState() => _LogWorkoutSheetState();
}

class _LogWorkoutSheetState extends ConsumerState<LogWorkoutSheet> {
  late final List<_DraftExercise> _exercises = [
    _DraftExercise()
      ..name = widget.prefillName ?? ''
      ..muscleGroup = widget.prefillMuscleGroup ?? muscleGroups.first,
  ];
  DateTime _date = DateTime.now();
  bool _saving = false;

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final validExercises =
        _exercises.where((e) => e.name.trim().isNotEmpty).toList();
    if (validExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise name')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final entry = WorkoutEntry(
        id: '',
        date: _date,
        exercises:
            validExercises
                .map(
                  (e) => ExerciseLog(
                    name: e.name.trim(),
                    muscleGroup: e.muscleGroup,
                    sets:
                        e.sets
                            .map(
                              (s) => ExerciseSet(
                                reps: s.reps,
                                weightKg: s.weightKg,
                              ),
                            )
                            .toList(),
                    exerciseId: e.exerciseId,
                  ),
                )
                .toList(),
        createdAt: DateTime.now(),
      );
      await ref.read(workoutRepoProvider).logWorkout(uid, entry);
      await ref.read(userRepoProvider).registerActivityAndGetStreak(uid);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log workout', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _exercises.length; i++) _buildExerciseCard(i),
            OutlinedButton.icon(
              onPressed: () => setState(() => _exercises.add(_DraftExercise())),
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save workout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(int index) {
    final exercise = _exercises[index];
    final catalog =
        ref.watch(exerciseListProvider).valueOrNull ?? const <Exercise>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final nameField = Autocomplete<Exercise>(
                  initialValue: TextEditingValue(text: exercise.name),
                  displayStringForOption: (e) => e.name,
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    if (query.isEmpty) return const Iterable<Exercise>.empty();
                    return catalog
                        .where((e) => e.name.toLowerCase().contains(query))
                        .take(8);
                  },
                  onSelected:
                      (selected) => setState(() {
                        exercise.name = selected.name;
                        exercise.exerciseId = selected.id;
                        exercise.muscleGroup = nearestMuscleGroup(selected);
                      }),
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Exercise name',
                      ),
                      onChanged: (v) {
                        exercise.name = v;
                        exercise.exerciseId = null;
                      },
                    );
                  },
                );
                final muscleDropdown = DropdownButtonFormField<String>(
                  value: exercise.muscleGroup,
                  decoration: const InputDecoration(labelText: 'Muscle group'),
                  items:
                      muscleGroups
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                  onChanged:
                      (v) => setState(
                        () => exercise.muscleGroup = v ?? exercise.muscleGroup,
                      ),
                );
                final removeButton = IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:
                      _exercises.length == 1
                          ? null
                          : () => setState(() => _exercises.removeAt(index)),
                );

                if (constraints.maxWidth < 480) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      nameField,
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: muscleDropdown),
                          removeButton,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 2, child: nameField),
                    const SizedBox(width: 8),
                    Expanded(child: muscleDropdown),
                    removeButton,
                  ],
                );
              },
            ),
            for (var s = 0; s < exercise.sets.length; s++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text('Set ${s + 1}'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: exercise.sets[s].reps.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Reps'),
                        onChanged:
                            (v) =>
                                exercise.sets[s].reps =
                                    int.tryParse(v) ?? exercise.sets[s].reps,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: exercise.sets[s].weightKg.toString(),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                        ),
                        onChanged:
                            (v) =>
                                exercise.sets[s].weightKg =
                                    double.tryParse(v) ??
                                    exercise.sets[s].weightKg,
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => exercise.sets.add(_DraftSet())),
                icon: const Icon(Icons.add),
                label: const Text('Add set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
