import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/providers.dart';
import '../../../../models/workout_plan.dart';
import '../../../../shared/widgets/app_card.dart';
import '../workout_editor/workout_plans_tab.dart' show workoutPlansProvider;
import 'plan_picker.dart';
import 'weekly_plan_providers.dart';

const _dayLabels = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Edits the *permanent* weekly routine — e.g. "Monday is always Push Day".
/// Changes here apply to every future week; they never touch a week that
/// already has its own one-off overrides (see WeeklyPlanTab).
class WeeklyRoutineEditorScreen extends ConsumerWidget {
  const WeeklyRoutineEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(weeklyRoutineProvider);
    final customPlans =
        ref.watch(workoutPlansProvider).valueOrNull ?? const <WorkoutPlan>[];
    final allPlans = ref.watch(availableWorkoutPlansProvider);
    final plansById = {for (final p in allPlans) p.id: p};
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Routine')),
      body: routineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (routine) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'This is your default week — it repeats every week unless '
                'you change a specific day from the Weekly Plan screen.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var weekday = 1; weekday <= 7; weekday++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dayLabels[weekday - 1],
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                plansById[routine.planForDay(weekday)]?.name ??
                                    'Rest',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await _pickPlanOrRest(
                              context,
                              customPlans,
                            );
                            if (picked == _cancelled) return;
                            final uid =
                                ref.read(authStateProvider).valueOrNull?.uid;
                            if (uid == null) return;
                            await ref
                                .read(weeklyRoutineRepoProvider)
                                .setDay(
                                  uid,
                                  weekday,
                                  picked == _restChoice ? null : picked,
                                );
                          },
                          child: const Text('Change'),
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

// Sentinels to distinguish "user picked Rest" / "user cancelled" from a
// real plan id — a saved plan's Firestore doc id, or one of the fixed
// sample-plan slugs (see sample_workout_plans.dart), never empty either way.
const _restChoice = '__rest__';
const _cancelled = '__cancelled__';

Future<String> _pickPlanOrRest(
  BuildContext context,
  List<WorkoutPlan> customPlans,
) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.hotel_outlined),
                  title: const Text('Rest'),
                  onTap: () => Navigator.pop(context, _restChoice),
                ),
                const Divider(height: 1),
                Flexible(
                  child: PlanOptionsList(
                    customPlans: customPlans,
                    samplePlans: sampleWorkoutPlansAsPlans,
                    onSelected: (p) => Navigator.pop(context, p.id),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
  return result ?? _cancelled;
}
