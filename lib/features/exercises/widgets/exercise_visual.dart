import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/exercise_pose_mapping.dart';
import '../data/exercise_pose_svgs.dart';
import 'category_visual.dart';

/// The visual shown for an exercise. Every thumbnail — photo or not — sits
/// on the same category-tinted backdrop with the same inset/rounding, so a
/// grid mixing real photos and pose-pictogram fallbacks reads as one
/// consistent, premium set rather than two different visual languages.
/// Prefers a real photo when one was confidently matched (see
/// assets/data/exercises.json and the curation script behind it) — all
/// sourced from free-exercise-db, which shoots every exercise in the same
/// studio style, so the photos themselves are consistent with each other
/// too, not just with the fallback icons. Falls back to the pose pictogram
/// (data/exercise_pose_svgs.dart) whenever no photo is set, OR at render
/// time if the photo fails to load.
class ExerciseVisual extends StatelessWidget {
  final String exerciseId;
  final String category;
  final String? photoUrl;
  final double iconSize;

  const ExerciseVisual({
    super.key,
    required this.exerciseId,
    required this.category,
    this.photoUrl,
    this.iconSize = 36,
  });

  Widget _pose(Color color) {
    final poseKey = exercisePoseByExerciseId[exerciseId];
    final svg = poseKey == null ? null : exercisePoseSvgs[poseKey];

    return Padding(
      padding: EdgeInsets.all(iconSize * 0.15),
      child:
          svg == null
              ? Icon(categoryIcon(category), size: iconSize, color: color)
              : SvgPicture.string(
                svg,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                fit: BoxFit.contain,
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    final url = photoUrl;

    return Container(
      color: color.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child:
          url == null
              ? _pose(color)
              : FractionallySizedBox(
                widthFactor: 0.86,
                heightFactor: 0.86,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(iconSize * 0.28),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => const SizedBox.expand(),
                    errorWidget: (context, _, __) => _pose(color),
                  ),
                ),
              ),
    );
  }
}
