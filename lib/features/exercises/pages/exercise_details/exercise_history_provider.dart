import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/exercise_history.dart';
import '../../../tracking/workouts/workouts_tab.dart';

final exerciseHistoryProvider =
    Provider.family<List<ExerciseHistoryPoint>, String>((ref, exerciseId) {
      final workouts =
          ref.watch(workoutHistoryProvider).valueOrNull ?? const [];
      return buildExerciseHistory(workouts: workouts, exerciseId: exerciseId);
    });
