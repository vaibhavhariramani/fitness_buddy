import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';

/// The small-caps section label used to open every dashboard/progress
/// section ("TODAY", "THIS WEEK", ...) — consistent rhythm instead of each
/// screen picking its own heading style.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expanded + ellipsis so a long title (e.g. "Training Volume
          // (effective sets)") truncates instead of overflowing the row
          // when paired with a wide trailing widget like a 4-option range
          // selector — a no-op for short titles that already fit.
          Expanded(
            child: Text(
              title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
