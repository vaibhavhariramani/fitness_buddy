/// A transparent, rule-based progression suggester — double progression
/// within a rep range, kept as a pure function (no widget/Firestore
/// dependency) so it's directly unit-testable per the app's established
/// "rule-based, not fabricated" approach to coaching logic.
library;

class ProgressionSuggestion {
  final double suggestedWeightKg;
  final int suggestedReps;

  /// A short, honest explanation of *why* — shown to the user rather than
  /// silently changing their plan for them.
  final String reason;

  const ProgressionSuggestion({
    required this.suggestedWeightKg,
    required this.suggestedReps,
    required this.reason,
  });
}

/// Suggests the next session's target for one exercise from the *previous*
/// session's logged sets, using a standard double-progression scheme within
/// [targetRepsMin]..[targetRepsMax]:
///
/// - Every set reached [targetRepsMax] -> weight up by [weightIncrementKg],
///   reps reset to [targetRepsMin] (a fresh rep range at the new weight).
/// - Every set reached at least [targetRepsMin] (but not all hit max) ->
///   same weight, one more rep than the lowest set last time.
/// - Otherwise -> same weight, same [targetRepsMin] target (the last
///   session wasn't fully hit yet — repeat it before adding difficulty).
///
/// Returns null when there's no previous data to progress from — the caller
/// should fall back to the exercise's own defaults in that case.
ProgressionSuggestion? suggestNextSession({
  required List<({int reps, double weightKg})> previousSets,
  int targetRepsMin = 8,
  int targetRepsMax = 12,
  double weightIncrementKg = 2.5,
}) {
  if (previousSets.isEmpty) return null;

  final lastWeight = previousSets.last.weightKg;
  final allHitMax = previousSets.every((s) => s.reps >= targetRepsMax);
  final allHitMin = previousSets.every((s) => s.reps >= targetRepsMin);

  if (allHitMax) {
    return ProgressionSuggestion(
      suggestedWeightKg: lastWeight + weightIncrementKg,
      suggestedReps: targetRepsMin,
      reason:
          'Every set hit $targetRepsMax+ reps last time — try adding weight.',
    );
  }

  if (allHitMin) {
    final lowestReps = previousSets
        .map((s) => s.reps)
        .reduce((a, b) => a < b ? a : b);
    final nextReps = (lowestReps + 1).clamp(targetRepsMin, targetRepsMax);
    return ProgressionSuggestion(
      suggestedWeightKg: lastWeight,
      suggestedReps: nextReps,
      reason: 'Same weight — aim for one more rep than last time.',
    );
  }

  return ProgressionSuggestion(
    suggestedWeightKg: lastWeight,
    suggestedReps: targetRepsMin,
    reason: 'Repeat this weight and aim for $targetRepsMin+ reps every set.',
  );
}
