import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/muscle_group_images.dart';
import '../utils/wger_image_proxy.dart';

/// A real muscle-diagram illustration (wger.de) for a broad muscle category
/// — a body silhouette with the relevant muscle highlighted, shown in its
/// original colors (tinting would erase the highlight-vs-body contrast that
/// makes it legible). Renders nothing at all if no diagram is mapped or it
/// fails to load — callers should wrap this so an empty result just
/// collapses rather than leaving a broken-looking gap.
class MuscleGroupImage extends StatelessWidget {
  final String category;
  final double height;

  const MuscleGroupImage({
    super.key,
    required this.category,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final url = muscleGroupImageUrls[category];
    if (url == null) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: CachedNetworkImage(
        imageUrl: wgerImageProxyUrl(url),
        fit: BoxFit.contain,
        placeholder: (context, _) => const SizedBox.shrink(),
        errorWidget: (context, _, __) => const SizedBox.shrink(),
      ),
    );
  }
}
