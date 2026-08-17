import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/streak.dart';
import '../../../models/user_profile.dart';
import '../../../models/weight_entry.dart';
import '../../../models/workout_entry.dart';

class FriendProgressSheet extends ConsumerWidget {
  final UserProfile friend;

  const FriendProgressSheet({required this.friend, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayStreak = StreakCalculator.currentDisplayStreak(
      storedStreak: friend.streakCount,
      lastLogDate: friend.lastLogDate,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                friend.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (friend.privacy.shareStreak)
                ListTile(
                  leading: const Icon(Icons.local_fire_department_outlined),
                  title: Text('$displayStreak day streak'),
                ),
              if (friend.privacy.shareWeight) ...[
                const Divider(),
                Text(
                  'Weight trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                StreamBuilder<List<WeightEntry>>(
                  stream: ref.read(weightRepoProvider).watchAll(friend.uid),
                  builder: (context, snapshot) {
                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No weight logs shared yet.'),
                      );
                    }
                    return Column(
                      children:
                          logs
                              .take(5)
                              .map(
                                (e) => ListTile(
                                  dense: true,
                                  title: Text(
                                    '${e.weightKg.toStringAsFixed(1)} kg',
                                  ),
                                  subtitle: Text(
                                    '${e.date.year}-${e.date.month}-${e.date.day}',
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  },
                ),
              ],
              if (friend.privacy.shareWorkouts) ...[
                const Divider(),
                Text(
                  'Recent workouts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                StreamBuilder<List<WorkoutEntry>>(
                  stream: ref.read(workoutRepoProvider).watchAll(friend.uid),
                  builder: (context, snapshot) {
                    final workouts = snapshot.data ?? [];
                    if (workouts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No workouts shared yet.'),
                      );
                    }
                    return Column(
                      children:
                          workouts
                              .take(5)
                              .map(
                                (w) => ListTile(
                                  dense: true,
                                  title: Text(
                                    '${w.exercises.length} exercise(s)',
                                  ),
                                  subtitle: Text(
                                    '${w.date.year}-${w.date.month}-${w.date.day}',
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  },
                ),
              ],
              if (!friend.privacy.shareWeight &&
                  !friend.privacy.shareWorkouts &&
                  !friend.privacy.shareStreak)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('This friend has kept their progress private.'),
                ),
            ],
          ),
    );
  }
}
