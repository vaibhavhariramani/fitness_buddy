import 'package:flutter/material.dart';

const _categoryIcons = {
  'Chest': Icons.fitness_center,
  'Back': Icons.rowing,
  'Shoulders': Icons.accessibility_new,
  'Legs': Icons.directions_walk,
  'Arms': Icons.sports_gymnastics,
  'Core': Icons.self_improvement,
  'Cardio': Icons.directions_run,
};

const _categoryColors = {
  'Chest': Colors.deepOrange,
  'Back': Colors.indigo,
  'Shoulders': Colors.purple,
  'Legs': Colors.green,
  'Arms': Colors.blue,
  'Core': Colors.teal,
  'Cardio': Colors.red,
};

IconData categoryIcon(String category) =>
    _categoryIcons[category] ?? Icons.fitness_center;

Color categoryColor(String category) =>
    _categoryColors[category] ?? Colors.blueGrey;

/// A category-colored icon tile used in place of a photo — this app has no
/// exercise images, so cards/detail headers use this consistent placeholder.
class CategoryVisual extends StatelessWidget {
  final String category;
  final double iconSize;

  const CategoryVisual({super.key, required this.category, this.iconSize = 36});

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(categoryIcon(category), size: iconSize, color: color),
    );
  }
}
