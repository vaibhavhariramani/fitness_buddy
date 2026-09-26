import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../exercises_tab_provider.dart';
import 'exercise_library/exercise_library_tab.dart';
import 'reports/muscle_reports_tab.dart';
import 'weekly_plan/weekly_plan_tab.dart';
import 'workout_editor/workout_plans_tab.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingTab = ref.read(pendingExercisesTabProvider);
    if (pendingTab != null) {
      // Deferred so we don't mutate provider state mid-build; clears it so a
      // later, ordinary visit to /exercises isn't stuck on this tab forever.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pendingExercisesTabProvider.notifier).state = null;
      });
    }
    return DefaultTabController(
      length: 4,
      initialIndex: pendingTab ?? 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exercises'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(
                text: 'All Exercises',
                icon: Icon(Icons.fitness_center_outlined),
              ),
              Tab(text: 'Workout Plans', icon: Icon(Icons.event_note_outlined)),
              Tab(
                text: 'This Week',
                icon: Icon(Icons.calendar_view_week_outlined),
              ),
              Tab(text: 'Muscle Reports', icon: Icon(Icons.insights_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ExerciseLibraryTab(),
            WorkoutPlansTab(),
            WeeklyPlanTab(),
            MuscleReportsTab(),
          ],
        ),
      ),
    );
  }
}
