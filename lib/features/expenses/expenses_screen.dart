import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../models/expense_entry.dart';

const _categories = [
  'Food',
  'Groceries',
  'Gym',
  'Supplements',
  'Subscription',
  'Transport',
  'Other',
];

final expensesProvider = StreamProvider.autoDispose<List<ExpenseEntry>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(expenseRepoProvider).watchAll(uid);
});

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  Future<void> _addExpense(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String category = _categories.first;
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Add expense'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items:
                            _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (c) => setState(() => category = c ?? category),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        subtitle: Text(DateFormat.yMMMd().format(date)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) setState(() => date = picked);
                        },
                      ),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );

    if (saved != true) return;
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    await ref
        .read(expenseRepoProvider)
        .add(
          uid,
          ExpenseEntry(
            id: '',
            date: date,
            category: category,
            amount: amount,
            note:
                noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Manager')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (expenses) {
          final now = DateTime.now();
          final thisMonth = expenses.where(
            (e) => e.date.year == now.year && e.date.month == now.month,
          );
          final monthTotal = thisMonth.fold<double>(
            0,
            (sum, e) => sum + e.amount,
          );
          final byCategory = <String, double>{};
          final entriesByCategory = <String, List<ExpenseEntry>>{};
          for (final e in thisMonth) {
            byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
            entriesByCategory.putIfAbsent(e.category, () => []).add(e);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This month: ${monthTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child:
                            byCategory.isEmpty
                                ? const Center(
                                  child: Text('No expenses this month.'),
                                )
                                : _CategoryBarChart(byCategory: byCategory),
                      ),
                    ],
                  ),
                ),
              ),
              if (entriesByCategory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Category breakdown by note',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final categoryEntry in entriesByCategory.entries)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${categoryEntry.key} · ${byCategory[categoryEntry.key]!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 140,
                            child: _NoteBarChart(
                              category: categoryEntry.key,
                              entries: categoryEntry.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              if (byCategory.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'By category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _CategoryTable(
                          byCategory: byCategory,
                          total: monthTotal,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (expenses.isEmpty)
                const Center(child: Text('No expenses logged yet.'))
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All transactions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _TransactionsTable(
                          expenses: expenses,
                          onDelete: (id) {
                            final uid =
                                ref.read(authStateProvider).valueOrNull?.uid;
                            if (uid != null) {
                              ref.read(expenseRepoProvider).delete(uid, id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

const _categoryColors = [
  Colors.blue,
  Colors.orange,
  Colors.green,
  Colors.purple,
  Colors.red,
  Colors.teal,
  Colors.brown,
];

Color _colorForCategory(String category) {
  final index = _categories.indexOf(category);
  return _categoryColors[(index < 0 ? 0 : index) % _categoryColors.length];
}

class _CategoryBarChart extends StatelessWidget {
  final Map<String, double> byCategory;

  const _CategoryBarChart({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    final categories = byCategory.keys.toList();
    final maxY = byCategory.values.fold<double>(0, (m, v) => v > m ? v : m);

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem:
                (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  '${categories[group.x]}\n${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= categories.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    categories[i],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < categories.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: byCategory[categories[i]]!,
                  color: _colorForCategory(categories[i]),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NoteBarChart extends StatelessWidget {
  final String category;
  final List<ExpenseEntry> entries;

  const _NoteBarChart({required this.category, required this.entries});

  @override
  Widget build(BuildContext context) {
    final byNote = <String, double>{};
    for (final e in entries) {
      final note = e.note?.trim();
      final label = (note == null || note.isEmpty) ? 'No note' : note;
      byNote[label] = (byNote[label] ?? 0) + e.amount;
    }
    final notes = byNote.keys.toList();
    final maxY = byNote.values.fold<double>(0, (m, v) => v > m ? v : m);
    final color = _colorForCategory(category);

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem:
                (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  '${notes[group.x]}\n${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= notes.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    notes[i],
                    style: const TextStyle(fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < notes.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: byNote[notes[i]]!,
                  color: color,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryTable extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;

  const _CategoryTable({required this.byCategory, required this.total});

  @override
  Widget build(BuildContext context) {
    final entries =
        byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Amount'), numeric: true),
          DataColumn(label: Text('% of month'), numeric: true),
        ],
        rows: [
          for (final entry in entries)
            DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colorForCategory(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key),
                    ],
                  ),
                ),
                DataCell(Text(entry.value.toStringAsFixed(2))),
                DataCell(
                  Text(
                    total == 0
                        ? '0%'
                        : '${(entry.value / total * 100).toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TransactionsTable extends StatelessWidget {
  final List<ExpenseEntry> expenses;
  final void Function(String id) onDelete;

  const _TransactionsTable({required this.expenses, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Amount'), numeric: true),
          DataColumn(label: Text('Note')),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (final e in expenses)
            DataRow(
              cells: [
                DataCell(Text(DateFormat.yMMMd().format(e.date))),
                DataCell(Text(e.category)),
                DataCell(Text(e.amount.toStringAsFixed(2))),
                DataCell(Text(e.note ?? '')),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDelete(e.id),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
