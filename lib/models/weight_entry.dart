import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;
  final String? note;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'weightKg': weightKg,
    'note': note,
  };

  factory WeightEntry.fromJson(String id, Map<String, dynamic> json) =>
      WeightEntry(
        id: id,
        date: (json['date'] as Timestamp).toDate(),
        weightKg: (json['weightKg'] as num).toDouble(),
        note: json['note'] as String?,
      );
}
