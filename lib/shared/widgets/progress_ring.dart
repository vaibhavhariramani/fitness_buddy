import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A minimal circular progress ring — deliberately not
/// `CircularProgressIndicator` (whose stroke/track treatment reads as
/// generic Material) so the calorie/macro hero metric on the dashboard gets
/// its own quiet, premium identity. Animates from 0 on first build.
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 140,
    this.strokeWidth = 12,
    required this.color,
    required this.trackColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              strokeWidth: strokeWidth,
              color: color,
              trackColor: trackColor,
            ),
            child: child == null ? null : Center(child: child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final fg =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
