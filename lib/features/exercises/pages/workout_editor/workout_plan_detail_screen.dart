import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tracking/workouts/pages/active_workout_page.dart';
import '../../models/workout_plan_template.dart';
import '../../providers/exercise_providers.dart';
import '../../widgets/add_to_workout_dialog.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/exercise_visual.dart';

class WorkoutPlanDetailScreen extends ConsumerWidget {
  final WorkoutPlanTemplate plan;

  const WorkoutPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(plan.focus, style: Theme.of(context).textTheme.titleMedium),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              '${plan.exercises.length} exercises · ~${plan.estimatedMinutes} min',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          for (final planned in plan.exercises)
            Builder(
              builder: (context) {
                final exercise = ref.watch(
                  exerciseByIdProvider(planned.exerciseId),
                );
                if (exercise == null) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ExerciseVisual(
                          exerciseId: exercise.id,
                          category: exercise.category,
                          photoUrl: exercise.photoUrl,
                          iconSize: 22,
                        ),
                      ),
                    ),
                    title: Text(exercise.name),
                    subtitle: Row(
                      children: [
                        Text(
                          planned.isTimed
                              ? '${planned.sets} x ${planned.targetReps}s'
                              : '${planned.sets} x ${planned.targetReps} reps',
                        ),
                        const SizedBox(width: 8),
                        DifficultyBadge(difficulty: exercise.difficulty),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.playlist_add),
                      tooltip: 'Log this exercise',
                      onPressed:
                          () => showAddToWorkoutDialog(context, ref, exercise),
                    ),
                    onTap: () => context.push('/exercises/${exercise.id}'),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Workout'),
            onPressed: () => _startWorkout(context),
          ),
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ActiveWorkoutPage(
              title: plan.name,
              seeds: [
                for (final p in plan.exercises)
                  SessionExerciseSeed(
                    exerciseId: p.exerciseId,
                    exerciseName:
                        p.exerciseId, // fallback only; ActiveWorkoutPage resolves the real name from the catalog
                    targetSets: p.sets,
                    targetReps: p.targetReps,
                    isTimed: p.isTimed,
                  ),
              ],
            ),
      ),
    );
  }
}
