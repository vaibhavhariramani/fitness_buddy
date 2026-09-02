import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSet {
  final int reps;
  final double weightKg;

  /// Reps in reserve — how many more reps the user felt they could have
  /// done. Null when not tracked for this set.
  final int? rir;

  /// Rate of perceived exertion, typically 1-10 in .5 increments. Null when
  /// not tracked for this set.
  final double? rpe;

  final bool isWarmup;
  final bool isFailure;

  const ExerciseSet({
    required this.reps,
    required this.weightKg,
    this.rir,
    this.rpe,
    this.isWarmup = false,
    this.isFailure = false,
  });

  Map<String, dynamic> toJson() => {
    'reps': reps,
    'weightKg': weightKg,
    'rir': rir,
    'rpe': rpe,
    'isWarmup': isWarmup,
    'isFailure': isFailure,
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    reps: (json['reps'] as num).toInt(),
    weightKg: (json['weightKg'] as num).toDouble(),
    rir: (json['rir'] as num?)?.toInt(),
    rpe: (json['rpe'] as num?)?.toDouble(),
    isWarmup: json['isWarmup'] as bool? ?? false,
    isFailure: json['isFailure'] as bool? ?? false,
  );
}

class ExerciseLog {
  final String name;
  final String muscleGroup;
  final List<ExerciseSet> sets;
  final bool isPr;

  /// Links this log to the Exercise catalog (lib/features/exercises), when
  /// the user picked a catalog match while logging rather than free-typing a
  /// name. Null for older logs and for free-typed names with no match —
  /// [name] stays the display/PR-key fallback either way.
  final String? exerciseId;

  final String? notes;

  const ExerciseLog({
    required this.name,
    required this.muscleGroup,
    required this.sets,
    this.isPr = false,
    this.exerciseId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'muscleGroup': muscleGroup,
    'sets': sets.map((s) => s.toJson()).toList(),
    'isPr': isPr,
    'exerciseId': exerciseId,
    'notes': notes,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    name: json['name'] as String? ?? '',
    muscleGroup: json['muscleGroup'] as String? ?? '',
    sets:
        ((json['sets'] as List?) ?? [])
            .map(
              (s) => ExerciseSet.fromJson(Map<String, dynamic>.from(s as Map)),
            )
            .toList(),
    isPr: json['isPr'] as bool? ?? false,
    exerciseId: json['exerciseId'] as String?,
    notes: json['notes'] as String?,
  );
}

class WorkoutEntry {
  final String id;
  final DateTime date;
  final List<ExerciseLog> exercises;
  final DateTime createdAt;
  final String? photoUrl;

  const WorkoutEntry({
    required this.id,
    required this.date,
    required this.exercises,
    required this.createdAt,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'photoUrl': photoUrl,
  };

  factory WorkoutEntry.fromJson(
    String id,
    Map<String, dynamic> json,
  ) => WorkoutEntry(
    id: id,
    date: (json['date'] as Timestamp).toDate(),
    exercises:
        ((json['exercises'] as List?) ?? [])
            .map(
              (e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    photoUrl: json['photoUrl'] as String?,
  );
}
