import 'package:flutter/material.dart';

class MacroProgressBar extends StatelessWidget {
  final String label;
  final double consumedG;
  final double? targetG;
  final Color color;

  const MacroProgressBar({
    super.key,
    required this.label,
    required this.consumedG,
    required this.targetG,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final target = targetG;
    final fraction =
        (target == null || target <= 0)
            ? 0.0
            : (consumedG / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(
              target == null
                  ? '${consumedG.toStringAsFixed(0)}g'
                  : '${consumedG.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
