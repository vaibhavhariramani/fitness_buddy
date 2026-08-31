import 'package:flutter/material.dart';

import '../../../../models/workout_plan.dart';

/// The "Your Plans" / "Sample Plans" grouped list shown inside both the
/// weekly-plan day picker and the routine editor's picker, factored out so
/// the two stay visually and behaviorally identical.
class PlanOptionsList extends StatelessWidget {
  final List<WorkoutPlan> customPlans;
  final List<WorkoutPlan> samplePlans;
  final ValueChanged<WorkoutPlan> onSelected;

  const PlanOptionsList({
    super.key,
    required this.customPlans,
    required this.samplePlans,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget sectionHeader(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );

    Widget planTile(WorkoutPlan p) => ListTile(
      title: Text(p.name),
      subtitle: Text(
        '${p.exercises.length} exercises · ~${p.estimatedMinutes} min',
      ),
      onTap: () => onSelected(p),
    );

    if (customPlans.isEmpty && samplePlans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No workout plans yet.'),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        if (customPlans.isNotEmpty) ...[
          sectionHeader('Your plans'),
          for (final p in customPlans) planTile(p),
        ],
        if (samplePlans.isNotEmpty) ...[
          sectionHeader('Sample plans'),
          for (final p in samplePlans) planTile(p),
        ],
      ],
    );
  }
}
