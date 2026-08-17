import 'package:cloud_firestore/cloud_firestore.dart';

class PlannedExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int targetReps;
  final bool isTimed;
  final int restSeconds;

  const PlannedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.targetReps,
    this.isTimed = false,
    this.restSeconds = 60,
  });

  PlannedExercise copyWith({
    int? sets,
    int? targetReps,
    bool? isTimed,
    int? restSeconds,
  }) => PlannedExercise(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets ?? this.sets,
    targetReps: targetReps ?? this.targetReps,
    isTimed: isTimed ?? this.isTimed,
    restSeconds: restSeconds ?? this.restSeconds,
  );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets,
    'targetReps': targetReps,
    'isTimed': isTimed,
    'restSeconds': restSeconds,
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> json) =>
      PlannedExercise(
        exerciseId: json['exerciseId'] as String? ?? '',
        exerciseName: json['exerciseName'] as String? ?? '',
        sets: json['sets'] as int? ?? 3,
        targetReps: json['targetReps'] as int? ?? 10,
        isTimed: json['isTimed'] as bool? ?? false,
        restSeconds: json['restSeconds'] as int? ?? 60,
      );
}

class WorkoutPlan {
  final String id;
  final String name;
  final List<PlannedExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Rough estimate: working time (sets * ~40s) plus rest between sets.
  int get estimatedMinutes {
    final seconds = exercises.fold<int>(
      0,
      (total, e) => total + e.sets * (40 + e.restSeconds),
    );
    return (seconds / 60).round();
  }

  WorkoutPlan copyWith({
    String? id,
    String? name,
    List<PlannedExercise>? exercises,
    DateTime? updatedAt,
  }) => WorkoutPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    exercises: exercises ?? this.exercises,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory WorkoutPlan.fromJson(
    String id,
    Map<String, dynamic> json,
  ) => WorkoutPlan(
    id: id,
    name: json['name'] as String? ?? 'Untitled plan',
    exercises:
        (json['exercises'] as List? ?? [])
            .map(
              (e) =>
                  PlannedExercise.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
