import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/exercise_pose_mapping.dart';
import '../data/exercise_pose_svgs.dart';
import 'category_visual.dart';

/// The visual shown for an exercise: a hand-drawn pose pictogram on a
/// category-tinted backdrop. Every exercise renders in the same illustrated
/// style — no photos — so a grid never mixes real human photography (which
/// varies by lighting, body, camera angle no matter how consistent the
/// source) with illustration; it also recolors automatically with the app
/// theme, so light/dark mode never leaves a mismatched photo behind.
class ExerciseVisual extends StatelessWidget {
  final String exerciseId;
  final String category;
  final double iconSize;

  const ExerciseVisual({
    super.key,
    required this.exerciseId,
    required this.category,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    final poseKey = exercisePoseByExerciseId[exerciseId];
    final svg = poseKey == null ? null : exercisePoseSvgs[poseKey];

    return Container(
      color: color.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(iconSize * 0.15),
        child:
            svg == null
                ? Icon(categoryIcon(category), size: iconSize, color: color)
                : SvgPicture.string(
                  svg,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  fit: BoxFit.contain,
                ),
      ),
    );
  }
}
