import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';

import 'body_diagram_paths.dart';

/// A front-view body silhouette, drawn from real anatomical path data (see
/// body_diagram_paths.dart), that highlights whichever muscle groups were
/// trained.
///
/// The app's muscle groups are broad categories (Chest, Back, Legs,
/// Shoulders, Arms, Core, Full body) rather than precise anatomy, so several
/// underlying regions light up together per category — "Back" is the one
/// exception: it's not visible from the front at all, so it's approximated
/// by the trapezius, the only back muscle with any front-view presence.
class MuscleBodyDiagram extends StatelessWidget {
  /// Muscle group name -> sets performed this week. Any group with a
  /// positive count is drawn highlighted; the rest stay a neutral fill.
  final Map<String, int> trainedSets;
  final double height;

  const MuscleBodyDiagram({
    super.key,
    required this.trainedSets,
    this.height = 200,
  });

  bool _isTrained(String group) =>
      (trainedSets['Full body'] ?? 0) > 0 || (trainedSets[group] ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onCategories = {
      for (final category in _categorySlugs.keys)
        category: _isTrained(category),
    };
    return SizedBox(
      height: height,
      width: height * bodyPathViewBox.width / bodyPathViewBox.height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder:
            (context, t, _) => CustomPaint(
              painter: _BodyPainter(
                progress: t,
                neutralFill: scheme.surfaceContainerHighest,
                outline: scheme.outlineVariant,
                highlight: scheme.primary,
                onCategories: onCategories,
              ),
            ),
      ),
    );
  }
}

/// Broad app category -> the MuscleMap slugs that light up for it. Slugs not
/// listed here (head, hair, neck, hands — cosmetic body parts with no
/// trainable-muscle meaning) always render in the neutral fill.
const _categorySlugs = {
  'Chest': ['chest', 'upperChest', 'lowerChest'],
  'Shoulders': ['deltoids', 'frontDeltoid'],
  'Arms': ['biceps', 'triceps', 'forearm'],
  'Core': ['abs', 'upperAbs', 'lowerAbs', 'obliques', 'serratus', 'hipFlexors'],
  'Legs': [
    'quadriceps',
    'innerQuad',
    'outerQuad',
    'calves',
    'tibialis',
    'adductors',
    'knees',
    'ankles',
    'feet',
  ],
  'Back': ['trapezius'],
};

/// slug -> category, the reverse of [_categorySlugs], built once.
final _slugCategory = {
  for (final entry in _categorySlugs.entries)
    for (final slug in entry.value) slug: entry.key,
};

/// Every slug's sub-paths merged into one [Path], parsed once and reused
/// across every repaint (including the 30-odd frames of the intro
/// animation) rather than re-parsing SVG strings every frame.
final Map<String, Path> _parsedBodyPaths = {
  for (final entry in bodyPartSvgPaths.entries)
    entry.key: _parsePaths(entry.value),
};

Path _parsePaths(List<String> svgPaths) {
  final path = Path();
  final proxy = _PathProxyAdapter(path);
  for (final d in svgPaths) {
    writeSvgPathDataToPath(d, proxy);
  }
  return path;
}

/// Adapts dart:ui's [Path] to path_parsing's [PathProxy] interface — the
/// method signatures already match exactly, so this is a pure forward.
class _PathProxyAdapter extends PathProxy {
  final Path path;
  _PathProxyAdapter(this.path);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

class _BodyPainter extends CustomPainter {
  final double progress;
  final Color neutralFill;
  final Color outline;
  final Color highlight;
  final Map<String, bool> onCategories;

  _BodyPainter({
    required this.progress,
    required this.neutralFill,
    required this.outline,
    required this.highlight,
    required this.onCategories,
  });

  Paint _fill(bool on) =>
      Paint()
        ..style = PaintingStyle.fill
        ..color =
            on
                ? highlight.withValues(alpha: 0.35 + 0.45 * progress)
                : neutralFill;

  Paint get _stroke =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = outline;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / bodyPathViewBox.width).clamp(
      0.0,
      size.height / bodyPathViewBox.height,
    );
    final dx =
        (size.width - bodyPathViewBox.width * scale) / 2 -
        bodyPathViewBox.left * scale;
    final dy =
        (size.height - bodyPathViewBox.height * scale) / 2 -
        bodyPathViewBox.top * scale;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    for (final entry in _parsedBodyPaths.entries) {
      final category = _slugCategory[entry.key];
      final on = category != null && (onCategories[category] ?? false);
      canvas.drawPath(entry.value, _fill(on));
      canvas.drawPath(entry.value, _stroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.highlight != highlight ||
      oldDelegate.neutralFill != neutralFill ||
      oldDelegate.outline != outline ||
      !_mapEquals(oldDelegate.onCategories, onCategories);

  static bool _mapEquals(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
