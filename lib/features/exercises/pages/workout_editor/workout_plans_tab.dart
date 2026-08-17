import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../models/workout_plan.dart';
import '../../data/sample_workout_plans.dart';
import '../../models/workout_plan_template.dart' as template;
import 'workout_plan_detail_screen.dart';
import 'workout_plan_editor_screen.dart';

final workoutPlansProvider = StreamProvider.autoDispose<List<WorkoutPlan>>((
  ref,
) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(workoutPlanRepoProvider).watchAll(uid);
});

class WorkoutPlansTab extends ConsumerWidget {
  const WorkoutPlansTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(workoutPlansProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutPlanEditorScreen(),
              ),
            ),
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text('My Plans', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          plansAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error: (e, _) => Text('Failed to load your plans: $e'),
            data: (plans) {
              if (plans.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'You haven\'t built any plans yet — tap "New plan" to create one.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              }
              return Column(
                children: [for (final plan in plans) _MyPlanCard(plan: plan)],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Sample Plans', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Ready-made plans for reference — tap to view.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          for (final plan in sampleWorkoutPlans) _SamplePlanCard(plan: plan),
        ],
      ),
    );
  }
}

class _MyPlanCard extends StatelessWidget {
  final WorkoutPlan plan;

  const _MyPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: const Icon(Icons.fitness_center),
        ),
        title: Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${plan.exercises.length} exercises · ~${plan.estimatedMinutes} min',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutPlanEditorScreen(plan: plan),
              ),
            ),
      ),
    );
  }
}

class _SamplePlanCard extends StatelessWidget {
  final template.WorkoutPlanTemplate plan;

  const _SamplePlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.event_note_outlined),
        ),
        title: Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${plan.focus}\n${plan.exercises.length} exercises · ~${plan.estimatedMinutes} min',
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutPlanDetailScreen(plan: plan),
              ),
            ),
      ),
    );
  }
}
