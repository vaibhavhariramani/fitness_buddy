import 'package:flutter/material.dart';

import '../../../../models/workout_entry.dart';

class WorkoutSummaryPage extends StatelessWidget {
  final WorkoutEntry entry;

  const WorkoutSummaryPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final totalSets = entry.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );
    final totalVolume = entry.exercises.fold<double>(
      0,
      (sum, e) =>
          sum + e.sets.fold<double>(0, (s, set) => s + set.weightKg * set.reps),
    );
    final prCount = entry.exercises.where((e) => e.isPr).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Workout Complete',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _StatRow(
                        label: 'Total volume',
                        value: '${totalVolume.toStringAsFixed(0)} kg',
                      ),
                      _StatRow(label: 'Sets completed', value: '$totalSets'),
                      _StatRow(
                        label: 'Exercises',
                        value: '${entry.exercises.length}',
                      ),
                      if (prCount > 0)
                        _StatRow(
                          label: 'New PRs',
                          value: '$prCount 🎉',
                          highlight: true,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (prCount > 0) ...[
                Text(
                  entry.exercises
                      .where((e) => e.isPr)
                      .map((e) => e.name)
                      .join(', '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
              ],
              FilledButton(
                onPressed:
                    () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style:
                highlight
                    ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )
                    : Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
