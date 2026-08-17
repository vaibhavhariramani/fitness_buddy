import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/exercise_pose_mapping.dart';
import '../data/exercise_pose_svgs.dart';
import '../utils/wger_image_proxy.dart';
import 'category_visual.dart';

/// The visual shown for an exercise. Prefers a real wger.de photo when one
/// was confidently matched for this exercise (see assets/data/exercises.json
/// and the curation script behind it); falls back to the original pose
/// pictogram (data/exercise_pose_svgs.dart) whenever no photo is set, OR at
/// render time if the photo fails to load — a network hiccup should never
/// show a broken image.
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

  Widget _poseFallback() {
    final color = categoryColor(category);
    final poseKey = exercisePoseByExerciseId[exerciseId];
    final svg = poseKey == null ? null : exercisePoseSvgs[poseKey];

    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
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
    final url = photoUrl;
    if (url == null) return _poseFallback();

    return CachedNetworkImage(
      imageUrl: wgerImageProxyUrl(url),
      fit: BoxFit.cover,
      placeholder:
          (context, _) =>
              Container(color: categoryColor(category).withValues(alpha: 0.15)),
      errorWidget: (context, _, __) => _poseFallback(),
    );
  }
}
