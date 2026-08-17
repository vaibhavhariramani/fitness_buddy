/// Personal-record (PR) detection using the Epley estimated 1-rep-max formula:
/// est1RM = weight * (1 + reps / 30)
library;

class SetResult {
  final double weightKg;
  final int reps;

  const SetResult({required this.weightKg, required this.reps});

  double get estimatedOneRepMax => weightKg * (1 + reps / 30);
}

class PrCheckResult {
  final bool isPr;
  final double bestWeightKg;
  final int bestReps;
  final double estOneRepMax;

  const PrCheckResult({
    required this.isPr,
    required this.bestWeightKg,
    required this.bestReps,
    required this.estOneRepMax,
  });
}

class PrCalculator {
  const PrCalculator._();

  /// Compares a newly logged set against the user's previous best for this
  /// exercise (by estimated 1RM) and returns whether it's a new PR plus the
  /// resulting best-to-store.
  static PrCheckResult check({
    required SetResult newSet,
    double? previousBestOneRepMax,
    double? previousBestWeightKg,
    int? previousBestReps,
  }) {
    final newOneRm = newSet.estimatedOneRepMax;
    final isPr =
        previousBestOneRepMax == null || newOneRm > previousBestOneRepMax;

    return PrCheckResult(
      isPr: isPr,
      bestWeightKg: isPr ? newSet.weightKg : previousBestWeightKg!,
      bestReps: isPr ? newSet.reps : previousBestReps!,
      estOneRepMax: isPr ? newOneRm : previousBestOneRepMax,
    );
  }
}
