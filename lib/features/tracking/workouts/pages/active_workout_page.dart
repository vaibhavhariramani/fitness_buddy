import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers.dart';
import '../../../../models/workout_entry.dart';
import '../../../exercises/providers/exercise_providers.dart';
import '../../../exercises/widgets/add_to_workout_dialog.dart'
    show nearestMuscleGroup;
import '../../../exercises/widgets/exercise_picker_sheet.dart';
import '../../../exercises/widgets/exercise_visual.dart';
import '../previous_performance_provider.dart';
import '../widgets/rest_timer_sheet.dart';
import 'workout_summary_page.dart';

/// What to seed a new active workout session with — a plan's exercises, or
/// nothing (the user adds exercises manually as they train).
class SessionExerciseSeed {
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final bool isTimed;
  final int restSeconds;

  const SessionExerciseSeed({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    this.isTimed = false,
    this.restSeconds = 90,
  });
}

class _DraftSet {
  int reps;
  double weightKg;
  int? rir;
  bool isWarmup = false;
  bool isFailure = false;
  bool completed = false;

  _DraftSet({required this.reps, required this.weightKg});
}

class _SessionExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final int restSeconds;
  final List<_DraftSet> sets;

  _SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.restSeconds,
    required this.sets,
  });
}

class ActiveWorkoutPage extends ConsumerStatefulWidget {
  final String title;
  final List<SessionExerciseSeed> seeds;

  const ActiveWorkoutPage({
    super.key,
    this.title = 'Workout',
    this.seeds = const [],
  });

  @override
  ConsumerState<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends ConsumerState<ActiveWorkoutPage> {
  late List<_SessionExercise> _exercises;
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _seeded = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  void initState() {
    super.initState();
    _exercises = [];
  }

  void _seedFromWidget() {
    if (_seeded) return;
    _seeded = true;
    for (final seed in widget.seeds) {
      final exercise = ref.read(exerciseByIdProvider(seed.exerciseId));
      final previous = ref.read(previousPerformanceProvider(seed.exerciseId));
      final defaultWeight =
          previous?.sets.isNotEmpty == true
              ? previous!.sets.last.weightKg
              : 0.0;
      _exercises.add(
        _SessionExercise(
          exerciseId: seed.exerciseId,
          name: exercise?.name ?? seed.exerciseName,
          muscleGroup:
              exercise == null ? 'Full body' : nearestMuscleGroup(exercise),
          restSeconds: seed.restSeconds,
          sets: List.generate(
            seed.targetSets,
            (_) => _DraftSet(reps: seed.targetReps, weightKg: defaultWeight),
          ),
        ),
      );
    }
  }

  Future<void> _addExercise() async {
    final exercise = await showExercisePickerSheet(context);
    if (exercise == null) return;
    final previous = ref.read(previousPerformanceProvider(exercise.id));
    final defaultWeight =
        previous?.sets.isNotEmpty == true ? previous!.sets.last.weightKg : 0.0;
    final defaultReps =
        previous?.sets.isNotEmpty == true ? previous!.sets.last.reps : 10;
    setState(() {
      _exercises.add(
        _SessionExercise(
          exerciseId: exercise.id,
          name: exercise.name,
          muscleGroup: nearestMuscleGroup(exercise),
          restSeconds: 90,
          sets: [_DraftSet(reps: defaultReps, weightKg: defaultWeight)],
        ),
      );
    });
  }

  void _completeSet(_SessionExercise exercise, _DraftSet set) {
    setState(() => set.completed = !set.completed);
    if (set.completed) {
      showRestTimerSheet(context, seconds: exercise.restSeconds);
    }
  }

  Future<void> _finish() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final logs = <ExerciseLog>[];
    for (final ex in _exercises) {
      final validSets = ex.sets.where((s) => s.reps > 0).toList();
      if (validSets.isEmpty) continue;
      logs.add(
        ExerciseLog(
          name: ex.name,
          muscleGroup: ex.muscleGroup,
          exerciseId: ex.exerciseId,
          sets:
              validSets
                  .map(
                    (s) => ExerciseSet(
                      reps: s.reps,
                      weightKg: s.weightKg,
                      rir: s.rir,
                      isWarmup: s.isWarmup,
                      isFailure: s.isFailure,
                    ),
                  )
                  .toList(),
        ),
      );
    }

    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log at least one set before finishing')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(workoutRepoProvider)
          .logWorkout(
            uid,
            WorkoutEntry(
              id: '',
              date: _date,
              exercises: logs,
              createdAt: DateTime.now(),
            ),
          );
      await ref.read(userRepoProvider).registerActivityAndGetStreak(uid);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSummaryPage(entry: saved),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _seedFromWidget();
    final completedCount =
        _exercises.where((e) => e.sets.every((s) => s.completed)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(DateFormat.yMMMd().format(_date)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$completedCount / ${_exercises.length} exercises',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final ex in _exercises)
            _ExerciseCard(exercise: ex, onCompleteSet: _completeSet),
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add exercise'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _finish,
            child:
                _saving
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Finish Workout'),
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  final _SessionExercise exercise;
  final void Function(_SessionExercise, _DraftSet) onCompleteSet;

  const _ExerciseCard({required this.exercise, required this.onCompleteSet});

  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  void _addSet() {
    final last =
        widget.exercise.sets.isNotEmpty ? widget.exercise.sets.last : null;
    setState(() {
      widget.exercise.sets.add(
        _DraftSet(reps: last?.reps ?? 10, weightKg: last?.weightKg ?? 0),
      );
    });
  }

  void _removeSet(int index) {
    setState(() => widget.exercise.sets.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final catalogExercise = ref.watch(
      exerciseByIdProvider(exercise.exerciseId),
    );
    final previous = ref.watch(
      previousPerformanceProvider(exercise.exerciseId),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (catalogExercise != null)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ExerciseVisual(
                        exerciseId: catalogExercise.id,
                        category: catalogExercise.category,
                        photoUrl: catalogExercise.wgerImageUrl,
                        iconSize: 18,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (previous != null && previous.sets.isNotEmpty)
                        Text(
                          'Previous: ${previous.sets.map((s) => '${s.weightKg.toStringAsFixed(0)}kg×${s.reps}').join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < exercise.sets.length; i++)
              _SetRow(
                index: i,
                set: exercise.sets[i],
                onChanged: () => setState(() {}),
                onComplete:
                    () => widget.onCompleteSet(exercise, exercise.sets[i]),
                onRemove:
                    exercise.sets.length == 1 ? null : () => _removeSet(i),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addSet,
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

class _SetRow extends StatelessWidget {
  final int index;
  final _DraftSet set;
  final VoidCallback onChanged;
  final VoidCallback onComplete;
  final VoidCallback? onRemove;

  const _SetRow({
    required this.index,
    required this.set,
    required this.onChanged,
    required this.onComplete,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  set.isWarmup ? 'W' : '${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue:
                      set.weightKg == 0 ? '' : set.weightKg.toString(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'kg',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    set.weightKg = double.tryParse(v) ?? set.weightKg;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: set.reps.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'reps',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    set.reps = int.tryParse(v) ?? set.reps;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: set.rir?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'RIR',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    set.rir = int.tryParse(v);
                    onChanged();
                  },
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(
                  set.completed
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color:
                      set.completed
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
                onPressed: onComplete,
              ),
              if (onRemove != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Wrap(
              spacing: 6,
              children: [
                FilterChip(
                  label: const Text('Warm-up'),
                  visualDensity: VisualDensity.compact,
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  selected: set.isWarmup,
                  onSelected: (v) {
                    set.isWarmup = v;
                    onChanged();
                  },
                ),
                FilterChip(
                  label: const Text('Failure'),
                  visualDensity: VisualDensity.compact,
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  selected: set.isFailure,
                  onSelected: (v) {
                    set.isFailure = v;
                    onChanged();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
