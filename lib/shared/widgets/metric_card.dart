import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_text_styles.dart';
import 'app_card.dart';

/// A single metric: label, a prominent stat value, an optional "/target"
/// suffix, an optional thin progress bar, and an optional trend line. The
/// workhorse of the dashboard's "Today" and "Body" sections — one widget
/// instead of every screen hand-rolling its own label+value Column.
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? target;
  final String? trend;
  final double? progress;
  final Color accentColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.target,
    this.trend,
    this.progress,
    required this.accentColor,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTextStyles.statMedium(scheme.onSurface)),
              if (target != null)
                Text(
                  target!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
          ],
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              trend!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
