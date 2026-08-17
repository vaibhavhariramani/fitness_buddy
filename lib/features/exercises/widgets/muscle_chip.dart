import 'package:flutter/material.dart';

class MuscleChip extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const MuscleChip({super.key, required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      backgroundColor: isPrimary ? scheme.primaryContainer : null,
      visualDensity: VisualDensity.compact,
    );
  }
}
