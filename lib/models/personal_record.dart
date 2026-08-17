import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalRecord {
  final String exerciseName;
  final double bestWeightKg;
  final int bestReps;
  final double estOneRepMax;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.exerciseName,
    required this.bestWeightKg,
    required this.bestReps,
    required this.estOneRepMax,
    required this.achievedAt,
  });

  Map<String, dynamic> toJson() => {
    'exerciseName': exerciseName,
    'bestWeightKg': bestWeightKg,
    'bestReps': bestReps,
    'estOneRepMax': estOneRepMax,
    'achievedAt': Timestamp.fromDate(achievedAt),
  };

  factory PersonalRecord.fromJson(
    String exerciseName,
    Map<String, dynamic> json,
  ) => PersonalRecord(
    exerciseName: exerciseName,
    bestWeightKg: (json['bestWeightKg'] as num).toDouble(),
    bestReps: (json['bestReps'] as num).toInt(),
    estOneRepMax: (json['estOneRepMax'] as num).toDouble(),
    achievedAt: (json['achievedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
