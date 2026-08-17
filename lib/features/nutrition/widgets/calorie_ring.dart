import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CalorieRing extends StatelessWidget {
  final double consumed;
  final double? target;

  const CalorieRing({super.key, required this.consumed, required this.target});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final target = this.target;
    final remaining = target == null ? null : (target - consumed);
    final consumedFraction =
        target == null || target <= 0
            ? 0.0
            : (consumed / target).clamp(0.0, 1.0);
    final overTarget = target != null && consumed > target;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  value: consumedFraction == 0 ? 0.001 : consumedFraction,
                  color: overTarget ? scheme.error : scheme.primary,
                  showTitle: false,
                  radius: 18,
                ),
                PieChartSectionData(
                  value: 1 - consumedFraction,
                  color: scheme.surfaceContainerHighest,
                  showTitle: false,
                  radius: 18,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                consumed.toStringAsFixed(0),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                target == null
                    ? 'kcal'
                    : (overTarget
                        ? '${(-remaining!).toStringAsFixed(0)} over'
                        : '${remaining!.toStringAsFixed(0)} left'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
