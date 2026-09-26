import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_haptics.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/progression.dart';
import '../../../../models/workout_entry.dart';
import '../../../../shared/utils/photo_picker.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../exercises/models/exercise.dart';
import '../../../exercises/providers/exercise_providers.dart';
import '../../../exercises/widgets/add_to_workout_dialog.dart'
    show nearestMuscleGroup;
import '../../../exercises/widgets/exercise_picker_sheet.dart';
import '../../../exercises/widgets/exercise_visual.dart';
import '../active_workout_draft.dart' as draft;
import '../previous_performance_provider.dart';
import '../rest_timer_default_controller.dart';
import '../widgets/rest_timer_sheet.dart';
import '../workout_story.dart';
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
  String exerciseId;
  String name;
  String muscleGroup;
  final int restSeconds;
  final List<_DraftSet> sets;
  String? memo;
  bool restTimerEnabled;

  /// Non-null when paired with another exercise in this session as a
  /// superset — shared by both members of the pair, cleared on both when
  /// unpaired so a "superset" never has just one lonely member.
  String? supersetGroupId;

  /// Stable per-instance identity for the reorderable list — exerciseId
  /// alone isn't unique (the same exercise can be added twice deliberately,
  /// e.g. two different set/rep schemes), and list index changes on every
  /// drag, so neither works as a Flutter list key on its own.
  final Key listKey = UniqueKey();

  _SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.restSeconds,
    required this.sets,
    this.restTimerEnabled = true,
  });
}

class ActiveWorkoutPage extends ConsumerStatefulWidget {
  final String title;
  final List<SessionExerciseSeed> seeds;

  /// True when opened from the "workout in progress" notification (tap or
  /// Resume) rather than started fresh — loads the persisted draft instead
  /// of seeding from [seeds].
  final bool restoreDraft;

  const ActiveWorkoutPage({
    super.key,
    this.title = 'Workout',
    this.seeds = const [],
    this.restoreDraft = false,
  });

  @override
  ConsumerState<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends ConsumerState<ActiveWorkoutPage> {
  late List<_SessionExercise> _exercises;
  DateTime _date = DateTime.now();
  DateTime _startedAt = DateTime.now();
  String _displayTitle = 'Workout';
  bool _saving = false;
  bool _seeded = false;
  Uint8List? _photoBytes;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  Future<void> _pickPhoto() async {
    final bytes = await pickPhotoFromCameraOrGallery(context);
    if (bytes == null) return;
    setState(() => _photoBytes = bytes);
  }

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
    _displayTitle = widget.title;
    // Gym screens lock/dim mid-set otherwise — released in dispose() no
    // matter how the session ends (finished, backed out, app killed).
    WakelockPlus.enable();
    // Recomputed from _startedAt each tick (rather than just incrementing by
    // 1s) so the displayed time stays correct even after the app was
    // backgrounded and this timer was suspended for a while. Also doubles
    // as the persistence tick — see _persistDraft.
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt));
      }
      _persistDraft();
    });

    if (widget.restoreDraft) {
      _seeded = true; // widget.seeds is empty for a resumed session anyway.
      _loadDraft();
    } else {
      draft.clearActiveWorkoutDraft();
      ref.read(draft.activeWorkoutSessionProvider.notifier).clear();
      ref.read(notificationServiceProvider).showWorkoutInProgress(widget.title);
    }
  }

  Future<void> _loadDraft() async {
    final loaded = await draft.loadActiveWorkoutDraft();
    if (!mounted) return;
    if (loaded == null) {
      // Notification was tapped after the session was already finished or
      // discarded elsewhere — fall back to a fresh session rather than a
      // confusing blank "resumed" screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workout in progress — starting fresh'),
        ),
      );
      ref.read(notificationServiceProvider).showWorkoutInProgress(widget.title);
      return;
    }
    setState(() {
      _displayTitle = loaded.title;
      _date = loaded.date;
      _startedAt = loaded.startedAt;
      _elapsed = DateTime.now().difference(_startedAt);
      _exercises = [
        for (final e in loaded.exercises)
          _SessionExercise(
              exerciseId: e.exerciseId,
              name: e.name,
              muscleGroup: e.muscleGroup,
              restSeconds: e.restSeconds,
              sets: [
                for (final s in e.sets)
                  _DraftSet(reps: s.reps, weightKg: s.weightKg)
                    ..rir = s.rir
                    ..isWarmup = s.isWarmup
                    ..isFailure = s.isFailure
                    ..completed = s.completed,
              ],
            )
            ..memo = e.memo
            ..restTimerEnabled = e.restTimerEnabled
            ..supersetGroupId = e.supersetGroupId,
      ];
    });
    ref.read(notificationServiceProvider).showWorkoutInProgress(loaded.title);
  }

  void _persistDraft() {
    if (_exercises.isEmpty) return;
    final snapshot = draft.WorkoutDraft(
      title: _displayTitle,
      date: _date,
      startedAt: _startedAt,
      exercises: [
        for (final e in _exercises)
          draft.DraftExercise(
            exerciseId: e.exerciseId,
            name: e.name,
            muscleGroup: e.muscleGroup,
            restSeconds: e.restSeconds,
            restTimerEnabled: e.restTimerEnabled,
            memo: e.memo,
            supersetGroupId: e.supersetGroupId,
            sets: [
              for (final s in e.sets)
                draft.DraftSet(
                  reps: s.reps,
                  weightKg: s.weightKg,
                  rir: s.rir,
                  isWarmup: s.isWarmup,
                  isFailure: s.isFailure,
                  completed: s.completed,
                ),
            ],
          ),
      ],
    );
    draft.saveActiveWorkoutDraft(snapshot);
    // Keeps HomeShell's "workout in progress" bar in sync — it deliberately
    // stays populated across this page being popped (back button), which is
    // exactly the "still running in the background" state that bar shows.
    ref.read(draft.activeWorkoutSessionProvider.notifier).update(snapshot);
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _seedFromWidget() {
    if (_seeded) return;
    _seeded = true;
    final restTimerDefault = ref.read(restTimerDefaultProvider);
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
          restTimerEnabled: restTimerDefault,
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
    AppHaptics.success();
    setState(() {
      _exercises.add(
        _SessionExercise(
          exerciseId: exercise.id,
          name: exercise.name,
          muscleGroup: nearestMuscleGroup(exercise),
          restSeconds: 90,
          restTimerEnabled: ref.read(restTimerDefaultProvider),
          sets: [_DraftSet(reps: defaultReps, weightKg: defaultWeight)],
        ),
      );
    });
  }

  void _completeSet(_SessionExercise exercise, _DraftSet set) {
    AppHaptics.tap();
    setState(() => set.completed = !set.completed);
    if (set.completed && exercise.restTimerEnabled) {
      showRestTimerSheet(context, seconds: exercise.restSeconds);
    }
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  void _removeExercise(_SessionExercise exercise) {
    setState(() {
      _exercises.remove(exercise);
      // A superset partner left alone isn't a superset anymore.
      final orphanedGroupId = exercise.supersetGroupId;
      if (orphanedGroupId != null &&
          _exercises.where((e) => e.supersetGroupId == orphanedGroupId).length <
              2) {
        for (final e in _exercises) {
          if (e.supersetGroupId == orphanedGroupId) e.supersetGroupId = null;
        }
      }
    });
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
      AppHaptics.warn();
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
      await draft.clearActiveWorkoutDraft();
      ref.read(draft.activeWorkoutSessionProvider.notifier).clear();
      // Stop the periodic persistence tick now that the draft is cleared —
      // otherwise a tick landing during the photo/story upload below could
      // re-write the draft to disk right after clearing it, leaving a stale
      // "resume this workout" draft behind for a workout that already saved.
      _elapsedTimer?.cancel();
      await ref.read(notificationServiceProvider).cancelWorkoutInProgress();
      final anyPr = saved.exercises.any((e) => e.isPr);
      anyPr ? AppHaptics.celebrate() : AppHaptics.success();

      try {
        await postWorkoutStory(
          ref: ref,
          uid: uid,
          saved: saved,
          photoBytes: _photoBytes,
        );
      } catch (_) {
        // Best-effort — see postWorkoutStory's doc comment.
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => WorkoutSummaryPage(
                  entry: saved,
                  duration: DateTime.now().difference(_startedAt),
                ),
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
    final totalSets = _exercises.fold<int>(0, (n, e) => n + e.sets.length);
    final completedSets = _exercises.fold<int>(
      0,
      (n, e) => n + e.sets.where((s) => s.completed).length,
    );
    final progress = totalSets == 0 ? 0.0 : completedSets / totalSets;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_displayTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: 4),
                Text(
                  _formatElapsed(_elapsed),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(DateFormat.yMMMd().format(_date)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completedSets / $totalSets sets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 250),
                    builder:
                        (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.workout,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_exercises.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // A card full of text fields and buttons can't be a
              // whole-card drag target (it'd fight every ordinary tap) —
              // each card gets its own explicit drag handle instead.
              buildDefaultDragHandles: false,
              itemCount: _exercises.length,
              onReorder: _reorderExercises,
              itemBuilder: (context, index) {
                final ex = _exercises[index];
                return Padding(
                  key: ex.listKey,
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ExerciseCard(
                    index: index,
                    exercise: ex,
                    allExercises: _exercises,
                    onCompleteSet: _completeSet,
                    onRemove: () => _removeExercise(ex),
                    onSessionChanged: () => setState(() {}),
                  ),
                );
              },
            ),
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add exercise'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
              _photoBytes == null
                  ? 'Add workout photo (optional)'
                  : 'Photo selected',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Finish Workout lives in the scrollable list itself (rather than
          // a fixed bottomNavigationBar) so it's always reachable by
          // scrolling even while the keyboard covers the bottom of the
          // screen — a fixed footer can end up hidden behind the keyboard
          // on some devices while editing a set deep in a long exercise list.
          SizedBox(
            width: double.infinity,
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
          SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
        ],
      ),
    );
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  final int index;
  final _SessionExercise exercise;
  final List<_SessionExercise> allExercises;
  final void Function(_SessionExercise, _DraftSet) onCompleteSet;
  final VoidCallback onRemove;

  /// Called after an action changes something another card's render might
  /// depend on (superset pairing) — triggers a rebuild up at the session
  /// level so the partner card picks up the change too.
  final VoidCallback onSessionChanged;

  const _ExerciseCard({
    required this.index,
    required this.exercise,
    required this.allExercises,
    required this.onCompleteSet,
    required this.onRemove,
    required this.onSessionChanged,
  });

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

  Future<void> _replaceExercise() async {
    final picked = await showExercisePickerSheet(context);
    if (picked == null) return;
    setState(() {
      widget.exercise.exerciseId = picked.id;
      widget.exercise.name = picked.name;
      widget.exercise.muscleGroup = nearestMuscleGroup(picked);
    });
  }

  Future<void> _editMemo() async {
    final controller = TextEditingController(text: widget.exercise.memo);
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Memo'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Elbows in, pause at the bottom',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (result == null) return;
    setState(() => widget.exercise.memo = result.isEmpty ? null : result);
  }

  Future<void> _toggleSuperset() async {
    final exercise = widget.exercise;
    if (exercise.supersetGroupId != null) {
      final groupId = exercise.supersetGroupId;
      setState(() {
        exercise.supersetGroupId = null;
        final remaining = widget.allExercises.where(
          (e) => e.supersetGroupId == groupId,
        );
        if (remaining.length == 1) remaining.first.supersetGroupId = null;
      });
      widget.onSessionChanged();
      return;
    }

    final candidates = widget.allExercises.where((e) => e != exercise).toList();
    if (candidates.isEmpty) return;
    final partner = await showModalBottomSheet<_SessionExercise>(
      context: context,
      useRootNavigator: true,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Superset with'),
                ),
                for (final c in candidates)
                  ListTile(
                    title: Text(c.name),
                    onTap: () => Navigator.pop(context, c),
                  ),
              ],
            ),
          ),
    );
    if (partner == null) return;
    final groupId = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      exercise.supersetGroupId = groupId;
      partner.supersetGroupId = groupId;
    });
    widget.onSessionChanged();
  }

  void _showInstructions(Exercise exercise) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(exercise.name),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${exercise.primaryMuscleNames} · ${exercise.equipmentNames}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (exercise.preparation.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Setup',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(exercise.preparation),
                    ],
                    if (exercise.execution.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'How to do it',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(exercise.execution),
                    ],
                    if (exercise.formTips.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Form tips',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      for (final tip in exercise.formTips) _BulletLine(tip),
                    ],
                    if (exercise.commonMistakes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Common mistakes',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      for (final m in exercise.commonMistakes) _BulletLine(m),
                    ],
                    if (exercise.safetyNotes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Safety notes',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      for (final s in exercise.safetyNotes) _BulletLine(s),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _openMenu() async {
    final exercise = widget.exercise;
    final action = await showModalBottomSheet<_ExerciseMenuAction>(
      context: context,
      useRootNavigator: true,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Replace exercise'),
                  onTap:
                      () => Navigator.pop(context, _ExerciseMenuAction.replace),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove exercise'),
                  onTap:
                      () => Navigator.pop(context, _ExerciseMenuAction.remove),
                ),
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: Text(exercise.memo == null ? 'Add memo' : 'Edit memo'),
                  onTap: () => Navigator.pop(context, _ExerciseMenuAction.memo),
                ),
                ListTile(
                  enabled: exercise.sets.length > 1,
                  leading: const Icon(Icons.remove_circle_outline),
                  title: const Text('Reduce sets'),
                  onTap:
                      () => Navigator.pop(
                        context,
                        _ExerciseMenuAction.reduceSets,
                      ),
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(
                    exercise.supersetGroupId == null
                        ? 'Create superset'
                        : 'Remove from superset',
                  ),
                  onTap:
                      () =>
                          Navigator.pop(context, _ExerciseMenuAction.superset),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.timer_outlined),
                  title: const Text('Rest timer'),
                  value: exercise.restTimerEnabled,
                  onChanged: (v) {
                    setState(() => exercise.restTimerEnabled = v);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ExerciseMenuAction.replace:
        await _replaceExercise();
      case _ExerciseMenuAction.remove:
        widget.onRemove();
      case _ExerciseMenuAction.memo:
        await _editMemo();
      case _ExerciseMenuAction.reduceSets:
        _removeSet(exercise.sets.length - 1);
      case _ExerciseMenuAction.superset:
        await _toggleSuperset();
    }
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
    final suggestion =
        previous == null || previous.sets.isEmpty
            ? null
            : suggestNextSession(
              previousSets: [
                for (final s in previous.sets)
                  (reps: s.reps, weightKg: s.weightKg),
              ],
            );
    final allComplete =
        exercise.sets.isNotEmpty && exercise.sets.every((s) => s.completed);

    return AppCard(
      accentColor:
          allComplete
              ? AppColors.workout
              : exercise.supersetGroupId != null
              ? AppColors.achievement
              : null,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.supersetGroupId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Row(
                children: [
                  const Icon(
                    Icons.link,
                    size: 14,
                    color: AppColors.achievement,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Superset',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.achievement,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (catalogExercise != null)
                GestureDetector(
                  onTap: () => _showInstructions(catalogExercise),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ExerciseVisual(
                        exerciseId: catalogExercise.id,
                        category: catalogExercise.category,
                        photoAsset: catalogExercise.photoAsset,
                        iconSize: 18,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!exercise.restTimerEnabled)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.timer_off_outlined, size: 14),
                          ),
                        Flexible(
                          child: Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    if (previous != null && previous.sets.isNotEmpty)
                      Text(
                        'Previous: ${previous.sets.map((s) => '${s.weightKg.toStringAsFixed(0)}kg×${s.reps}').join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (suggestion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Suggested: ${suggestion.suggestedWeightKg.toStringAsFixed(1)}kg × ${suggestion.suggestedReps}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: AppColors.achievement,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (exercise.memo != null && exercise.memo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 13,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                exercise.memo!,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (allComplete)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.workout,
                    size: 20,
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.more_vert),
                onPressed: _openMenu,
              ),
              ReorderableDragStartListener(
                index: widget.index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.drag_handle),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < exercise.sets.length; i++)
            _SetRow(
              index: i,
              set: exercise.sets[i],
              onChanged: () => setState(() {}),
              onComplete:
                  () => widget.onCompleteSet(exercise, exercise.sets[i]),
              onRemove: exercise.sets.length == 1 ? null : () => _removeSet(i),
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
    );
  }
}

enum _ExerciseMenuAction { replace, remove, memo, reduceSets, superset }

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const Text('•  '), Expanded(child: Text(text))],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            set.completed
                ? AppColors.workout.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
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
              _CompleteButton(completed: set.completed, onPressed: onComplete),
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

/// A comfortably-sized (44dp) tap target wrapping the compact check icon —
/// the icon itself stays visually small, but the tappable area meets a
/// comfortable touch-target size for quick in-gym logging.
class _CompleteButton extends StatelessWidget {
  final bool completed;
  final VoidCallback onPressed;

  const _CompleteButton({required this.completed, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            completed ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 22,
            color: completed ? AppColors.workout : scheme.outline,
          ),
        ),
      ),
    );
  }
}
