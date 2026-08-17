import 'package:flutter/material.dart';

import 'exercise_library/exercise_library_tab.dart';
import 'reports/muscle_reports_tab.dart';
import 'workout_editor/workout_plans_tab.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exercises'),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: 'All Exercises',
                icon: Icon(Icons.fitness_center_outlined),
              ),
              Tab(text: 'Workout Plans', icon: Icon(Icons.event_note_outlined)),
              Tab(text: 'Muscle Reports', icon: Icon(Icons.insights_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ExerciseLibraryTab(),
            WorkoutPlansTab(),
            MuscleReportsTab(),
          ],
        ),
      ),
    );
  }
}
