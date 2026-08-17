import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/pr.dart';
import '../../models/personal_record.dart';
import '../../models/workout_entry.dart';

class WorkoutRepo {
  final FirebaseFirestore _db;

  WorkoutRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _workoutsCol(String uid) =>
      _db.collection('users').doc(uid).collection('workouts');

  DocumentReference<Map<String, dynamic>> _prDoc(
    String uid,
    String exerciseName,
  ) => _db
      .collection('users')
      .doc(uid)
      .collection('personalRecords')
      .doc(exerciseName.toLowerCase().trim());

  Stream<List<WorkoutEntry>> watchAll(String uid) {
    return _workoutsCol(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => WorkoutEntry.fromJson(d.id, d.data()))
                  .toList(),
        );
  }

  Stream<List<PersonalRecord>> watchPersonalRecords(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('personalRecords')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => PersonalRecord.fromJson(d.id, d.data()))
                  .toList(),
        );
  }

  /// Saves a workout, checking each exercise's heaviest set against the
  /// stored PR for that exercise (via a transaction per exercise) and
  /// flagging `isPr` accordingly before persisting the workout document.
  /// Returns the saved entry (with `isPr` flags filled in and a real id) so
  /// callers can show a post-workout summary without a second fetch.
  Future<WorkoutEntry> logWorkout(String uid, WorkoutEntry entry) async {
    final flaggedExercises = <ExerciseLog>[];

    for (final exercise in entry.exercises) {
      if (exercise.sets.isEmpty) {
        flaggedExercises.add(exercise);
        continue;
      }

      final bestSetThisSession = exercise.sets.reduce(
        (a, b) =>
            SetResult(weightKg: a.weightKg, reps: a.reps).estimatedOneRepMax >
                    SetResult(
                      weightKg: b.weightKg,
                      reps: b.reps,
                    ).estimatedOneRepMax
                ? a
                : b,
      );

      final isPr = await _db.runTransaction<bool>((tx) async {
        final prRef = _prDoc(uid, exercise.name);
        final prSnap = await tx.get(prRef);

        final check = PrCalculator.check(
          newSet: SetResult(
            weightKg: bestSetThisSession.weightKg,
            reps: bestSetThisSession.reps,
          ),
          previousBestOneRepMax:
              prSnap.exists
                  ? (prSnap.data()!['estOneRepMax'] as num?)?.toDouble()
                  : null,
          previousBestWeightKg:
              prSnap.exists
                  ? (prSnap.data()!['bestWeightKg'] as num?)?.toDouble()
                  : null,
          previousBestReps:
              prSnap.exists
                  ? (prSnap.data()!['bestReps'] as num?)?.toInt()
                  : null,
        );

        if (check.isPr) {
          tx.set(
            prRef,
            PersonalRecord(
              exerciseName: exercise.name,
              bestWeightKg: check.bestWeightKg,
              bestReps: check.bestReps,
              estOneRepMax: check.estOneRepMax,
              achievedAt: entry.date,
            ).toJson(),
          );
        }

        return check.isPr;
      });

      flaggedExercises.add(
        ExerciseLog(
          name: exercise.name,
          muscleGroup: exercise.muscleGroup,
          sets: exercise.sets,
          isPr: isPr,
          exerciseId: exercise.exerciseId,
          notes: exercise.notes,
        ),
      );
    }

    final savedEntry = WorkoutEntry(
      id: '',
      date: entry.date,
      exercises: flaggedExercises,
      createdAt: entry.createdAt,
    );
    final ref = await _workoutsCol(uid).add(savedEntry.toJson());
    return WorkoutEntry(
      id: ref.id,
      date: savedEntry.date,
      exercises: savedEntry.exercises,
      createdAt: savedEntry.createdAt,
    );
  }
}
