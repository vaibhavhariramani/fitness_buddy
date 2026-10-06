import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthSummary {
  final int steps;
  final Duration? sleep;

  const HealthSummary({required this.steps, this.sleep});
}

/// Read-only bridge to Apple Health (which also receives Apple Watch and
/// most smart-watch data). Values are shown on-device only and never written
/// to Firestore, so they stay out of the app's data-collection footprint.
class HealthService {
  static const _connectedKey = 'apple_health_connected';

  final Health _health = Health();

  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_connectedKey) ?? false;
  }

  Future<bool> connect() async {
    final granted = await _health.requestAuthorization(
      const [HealthDataType.STEPS, HealthDataType.SLEEP_ASLEEP],
      permissions: const [HealthDataAccess.READ, HealthDataAccess.READ],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_connectedKey, granted);
    return granted;
  }

  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_connectedKey, false);
  }

  /// Steps since local midnight, plus sleep from 6pm yesterday until now.
  /// Apple reports sleep as separate stage intervals, so the total is their
  /// summed duration — overlapping intervals from multiple sources can
  /// over-count, which is acceptable for a dashboard glance.
  Future<HealthSummary> today() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;

    final sleepStart = midnight.subtract(const Duration(hours: 6));
    final sleepPoints = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.SLEEP_ASLEEP],
      startTime: sleepStart,
      endTime: now,
    );
    Duration? sleep;
    for (final p in sleepPoints) {
      sleep = (sleep ?? Duration.zero) + p.dateTo.difference(p.dateFrom);
    }

    return HealthSummary(steps: steps, sleep: sleep);
  }
}

final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

final healthConnectedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(healthServiceProvider).isConnected(),
);

/// Null when the user hasn't connected Apple Health — the dashboard hides its
/// steps card in that case rather than showing zeros that look like data.
final healthSummaryProvider = FutureProvider.autoDispose<HealthSummary?>((
  ref,
) async {
  final service = ref.watch(healthServiceProvider);
  if (!await service.isConnected()) return null;
  return service.today();
});
