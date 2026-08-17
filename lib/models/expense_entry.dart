import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseEntry {
  final String id;
  final DateTime date;
  final String category;
  final double amount;
  final String? note;

  const ExpenseEntry({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'category': category,
    'amount': amount,
    'note': note,
  };

  factory ExpenseEntry.fromJson(String id, Map<String, dynamic> json) =>
      ExpenseEntry(
        id: id,
        date: (json['date'] as Timestamp).toDate(),
        category: json['category'] as String? ?? 'Other',
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String?,
      );
}
