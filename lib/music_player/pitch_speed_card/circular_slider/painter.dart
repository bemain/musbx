import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider/utils.dart';

class CircularSliderPainter extends CustomPainter {
  CircularSliderPainter({
    required this.activeFraction,
    required this.startAngle,
    required this.endAngle,
    required this.radius,
    this.thumbRadius = 10,
    this.activeTrackWidth = 6,
    this.disabled = false,
    required this.theme,
  });

  final double startAngle;
  final double endAngle;

  final double radius;

  final double activeFraction;

  final bool disabled;
  final ThemeData theme;
  final double activeTrackWidth;
  final double thumbRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Color activeColor =
        theme.sliderTheme.activeTrackColor ?? theme.colorScheme.primary;
    final Color inactiveColor = theme.sliderTheme.inactiveTrackColor ??
        theme.colorScheme.primary.withOpacity(0.24);

    final Color disabledActiveColor =
        theme.sliderTheme.disabledActiveTrackColor ??
            theme.colorScheme.onSurface.withOpacity(0.32);
    final Color disabledInactiveColor =
        theme.sliderTheme.disabledInactiveTrackColor ??
            theme.colorScheme.onSurface.withOpacity(0.12);

    Paint activePaint = Paint()
      ..color = disabled ? disabledActiveColor : activeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeTrackWidth;
    Paint inactivePaint = Paint()
      ..color = disabled ? disabledInactiveColor : inactiveColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeTrackWidth / 2;

    final Offset center = Offset(size.width / 2, size.height / 2);

    // Draw inactive track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle - pi / 2 + (endAngle - startAngle) * activeFraction,
      (endAngle - startAngle) * (1 - activeFraction),
      false,
      inactivePaint,
    );
    // Draw active track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle - pi / 2,
      (endAngle - startAngle) * activeFraction,
      false,
      activePaint,
    );

    // Draw thumb
    final Paint thumbPaint = Paint()
      ..color = disabled ? disabledActiveColor : activeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final double thumbAngle =
        startAngle - pi / 2 + (endAngle - startAngle) * activeFraction;
    final Offset thumbOffset = angleToPoint(thumbAngle, center, radius);
    canvas.drawCircle(thumbOffset, thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant CircularSliderPainter oldDelegate) {
    return activeFraction != oldDelegate.activeFraction ||
        startAngle != oldDelegate.startAngle ||
        endAngle != oldDelegate.endAngle ||
        theme != oldDelegate.theme;
  }
}
