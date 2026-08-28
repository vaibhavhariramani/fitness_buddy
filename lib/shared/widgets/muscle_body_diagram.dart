import 'package:flutter/material.dart';

/// A stylized front-view body silhouette that highlights whichever muscle
/// groups were trained — built from simple geometric primitives (no SVG
/// asset) so it scales crisply and recolors with the theme for free.
///
/// The app's muscle groups are broad categories (Chest, Back, Legs,
/// Shoulders, Arms, Core, Full body) rather than precise anatomy, so the
/// mapping here is intentionally simplified: "Back" — not visible from the
/// front — highlights a strip at each side of the torso (roughly where the
/// lats read from the front), and "Full body" highlights every region.
class MuscleBodyDiagram extends StatelessWidget {
  /// Muscle group name -> sets performed this week. Any group with a
  /// positive count is drawn highlighted; the rest stay a neutral outline.
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
    return SizedBox(
      height: height,
      width: height * 0.62,
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
                chestOn: _isTrained('Chest'),
                shouldersOn: _isTrained('Shoulders'),
                armsOn: _isTrained('Arms'),
                coreOn: _isTrained('Core'),
                legsOn: _isTrained('Legs'),
                backOn: _isTrained('Back'),
              ),
            ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final double progress;
  final Color neutralFill;
  final Color outline;
  final Color highlight;
  final bool chestOn;
  final bool shouldersOn;
  final bool armsOn;
  final bool coreOn;
  final bool legsOn;
  final bool backOn;

  _BodyPainter({
    required this.progress,
    required this.neutralFill,
    required this.outline,
    required this.highlight,
    required this.chestOn,
    required this.shouldersOn,
    required this.armsOn,
    required this.coreOn,
    required this.legsOn,
    required this.backOn,
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
        ..strokeWidth = 1.5
        ..color = outline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    void region(RRect rrect, bool on) {
      canvas.drawRRect(rrect, _fill(on));
      canvas.drawRRect(rrect, _stroke);
    }

    // Head (neutral — not a trainable muscle group).
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.07),
      w * 0.14,
      Paint()..color = neutralFill,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.07), w * 0.14, _stroke);

    // Neck.
    region(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.16),
          width: w * 0.14,
          height: h * 0.06,
        ),
        const Radius.circular(4),
      ),
      false,
    );

    // Back strips (sides of torso — lats hinted from the front).
    region(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.22, w * 0.09, h * 0.24),
        const Radius.circular(8),
      ),
      backOn,
    );
    region(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.75, h * 0.22, w * 0.09, h * 0.24),
        const Radius.circular(8),
      ),
      backOn,
    );

    // Shoulders.
    region(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.27, h * 0.22),
          width: w * 0.20,
          height: h * 0.09,
        ),
        const Radius.circular(10),
      ),
      shouldersOn,
    );
    region(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.73, h * 0.22),
          width: w * 0.20,
          height: h * 0.09,
        ),
        const Radius.circular(10),
      ),
      shouldersOn,
    );

    // Arms.
    region(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.27, w * 0.13, h * 0.32),
        const Radius.circular(12),
      ),
      armsOn,
    );
    region(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.81, h * 0.27, w * 0.13, h * 0.32),
        const Radius.circular(12),
      ),
      armsOn,
    );

    // Chest.
    region(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.30),
          width: w * 0.40,
          height: h * 0.15,
        ),
        const Radius.circular(12),
      ),
      chestOn,
    );

    // Core.
    region(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.47),
          width: w * 0.30,
          height: h * 0.16,
        ),
        const Radius.circular(10),
      ),
      coreOn,
    );

    // Legs.
    region(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.58, w * 0.16, h * 0.40),
        const Radius.circular(14),
      ),
      legsOn,
    );
    region(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.54, h * 0.58, w * 0.16, h * 0.40),
        const Radius.circular(14),
      ),
      legsOn,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.chestOn != chestOn ||
      oldDelegate.shouldersOn != shouldersOn ||
      oldDelegate.armsOn != armsOn ||
      oldDelegate.coreOn != coreOn ||
      oldDelegate.legsOn != legsOn ||
      oldDelegate.backOn != backOn ||
      oldDelegate.highlight != highlight ||
      oldDelegate.neutralFill != neutralFill;
}
