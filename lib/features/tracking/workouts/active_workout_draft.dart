import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/workout_entry.dart';
import '../../../services/repositories/user_repo.dart';
import '../../../services/repositories/workout_repo.dart';

const _draftPrefsKey = 'active_workout_draft_v1';

class DraftSet {
  final int reps;
  final double weightKg;
  final int? rir;
  final bool isWarmup;
  final bool isFailure;
  final bool completed;

  const DraftSet({
    required this.reps,
    required this.weightKg,
    this.rir,
    this.isWarmup = false,
    this.isFailure = false,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'reps': reps,
    'weightKg': weightKg,
    'rir': rir,
    'isWarmup': isWarmup,
    'isFailure': isFailure,
    'completed': completed,
  };

  factory DraftSet.fromJson(Map<String, dynamic> json) => DraftSet(
    reps: json['reps'] as int,
    weightKg: (json['weightKg'] as num).toDouble(),
    rir: json['rir'] as int?,
    isWarmup: json['isWarmup'] as bool? ?? false,
    isFailure: json['isFailure'] as bool? ?? false,
    completed: json['completed'] as bool? ?? false,
  );
}

class DraftExercise {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final int restSeconds;
  final bool restTimerEnabled;
  final String? memo;
  final String? supersetGroupId;
  final List<DraftSet> sets;

  const DraftExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.restSeconds,
    required this.restTimerEnabled,
    this.memo,
    this.supersetGroupId,
    required this.sets,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'muscleGroup': muscleGroup,
    'restSeconds': restSeconds,
    'restTimerEnabled': restTimerEnabled,
    'memo': memo,
    'supersetGroupId': supersetGroupId,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  factory DraftExercise.fromJson(Map<String, dynamic> json) => DraftExercise(
    exerciseId: json['exerciseId'] as String,
    name: json['name'] as String,
    muscleGroup: json['muscleGroup'] as String,
    restSeconds: json['restSeconds'] as int? ?? 90,
    restTimerEnabled: json['restTimerEnabled'] as bool? ?? true,
    memo: json['memo'] as String?,
    supersetGroupId: json['supersetGroupId'] as String?,
    sets:
        (json['sets'] as List)
            .map((s) => DraftSet.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
  );
}

/// A serializable snapshot of an in-progress [ActiveWorkoutPage] session —
/// persisted to disk so the workout survives the app being backgrounded or
/// fully killed, and can be resumed (or saved directly from the "Stop &
/// Save" notification action) without that in-memory state.
class WorkoutDraft {
  final String title;
  final DateTime date;
  final DateTime startedAt;
  final List<DraftExercise> exercises;

  const WorkoutDraft({
    required this.title,
    required this.date,
    required this.startedAt,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date.toIso8601String(),
    'startedAt': startedAt.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutDraft.fromJson(Map<String, dynamic> json) => WorkoutDraft(
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    startedAt: DateTime.parse(json['startedAt'] as String),
    exercises:
        (json['exercises'] as List)
            .map(
              (e) =>
                  DraftExercise.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
  );
}

Future<void> saveActiveWorkoutDraft(WorkoutDraft draft) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_draftPrefsKey, jsonEncode(draft.toJson()));
}

Future<WorkoutDraft?> loadActiveWorkoutDraft() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_draftPrefsKey);
  if (raw == null) return null;
  try {
    return WorkoutDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    // Corrupt/outdated draft shape — treat as "nothing to resume" rather
    // than crashing whoever's reading it (foreground page or the
    // background notification-action handler).
    return null;
  }
}

Future<void> clearActiveWorkoutDraft() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_draftPrefsKey);
}

/// Saves whatever's in the persisted draft as a finished workout. Used by
/// the "Stop & Save" notification action, which can run with no Flutter
/// widget tree at all (app backgrounded, or fully killed and woken into a
/// fresh background isolate) — so this talks to Firebase directly rather
/// than through any Riverpod provider or the page's own state.
Future<void> stopAndSaveActiveWorkoutDraft() async {
  final draft = await loadActiveWorkoutDraft();
  if (draft == null) return;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final logs = <ExerciseLog>[];
  for (final ex in draft.exercises) {
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

  if (logs.isNotEmpty) {
    await WorkoutRepo().logWorkout(
      uid,
      WorkoutEntry(
        id: '',
        date: draft.date,
        exercises: logs,
        createdAt: DateTime.now(),
      ),
    );
    await UserRepo().registerActivityAndGetStreak(uid);
  }
  await clearActiveWorkoutDraft();
}
