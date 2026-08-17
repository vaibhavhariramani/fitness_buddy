import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'meals/meals_tab.dart';
import 'weight/weight_tab.dart';
import 'workouts/workout_prefill_provider.dart';
import 'workouts/workouts_tab.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPendingWorkoutPrefill =
        ref.read(pendingWorkoutPrefillProvider) != null;
    return DefaultTabController(
      length: 3,
      initialIndex: hasPendingWorkoutPrefill ? 2 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Tracking'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Weight', icon: Icon(Icons.monitor_weight_outlined)),
              Tab(text: 'Meals', icon: Icon(Icons.restaurant_outlined)),
              Tab(text: 'Workouts', icon: Icon(Icons.fitness_center_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [WeightTab(), MealsTab(), WorkoutsTab()],
        ),
      ),
    );
  }
}
