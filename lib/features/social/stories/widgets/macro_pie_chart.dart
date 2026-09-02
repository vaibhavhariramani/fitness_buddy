import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A small donut chart splitting a meal's calories by macro (protein/carb/fat
/// converted to their calorie share: protein & carb at 4 kcal/g, fat at
/// 9 kcal/g) — used as the overlay on a meal story.
class MacroPieChart extends StatelessWidget {
  final double proteinG;
  final double carbG;
  final double fatG;

  const MacroPieChart({
    super.key,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  static const _proteinColor = Colors.redAccent;
  static const _carbColor = Colors.orangeAccent;
  static const _fatColor = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    final proteinCal = proteinG * 4;
    final carbCal = carbG * 4;
    final fatCal = fatG * 9;
    final total = proteinCal + carbCal + fatCal;

    if (total <= 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 14,
              sections: [
                PieChartSectionData(
                  value: proteinCal,
                  color: _proteinColor,
                  showTitle: false,
                  radius: 14,
                ),
                PieChartSectionData(
                  value: carbCal,
                  color: _carbColor,
                  showTitle: false,
                  radius: 14,
                ),
                PieChartSectionData(
                  value: fatCal,
                  color: _fatColor,
                  showTitle: false,
                  radius: 14,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Legend(
              color: _proteinColor,
              label: 'Protein ${proteinG.toStringAsFixed(0)}g',
            ),
            _Legend(
              color: _carbColor,
              label: 'Carbs ${carbG.toStringAsFixed(0)}g',
            ),
            _Legend(color: _fatColor, label: 'Fat ${fatG.toStringAsFixed(0)}g'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
