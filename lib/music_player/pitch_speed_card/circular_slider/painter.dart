import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider/utils.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider_theme.dart';

class CircularSliderPainter extends CustomPainter {
  CircularSliderPainter({
    required this.activeFraction,
    required this.startAngle,
    required this.endAngle,
    required this.radius,
    this.disabled = false,
    required this.theme,
  });

  final double startAngle;
  final double endAngle;

  final double radius;

  final double activeFraction;

  final bool disabled;
  final CircularSliderTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    Paint activePaint = Paint()
      ..color =
          disabled ? theme.disabledActiveTrackColor : theme.activeTrackColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.trackHeight + theme.activeTrackAdditionalHeight;
    Paint inactivePaint = Paint()
      ..color =
          disabled ? theme.disabledInactiveTrackColor : theme.inactiveTrackColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.trackHeight;

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
      ..color = disabled ? theme.disabledThumbColor : theme.thumbColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final double thumbAngle =
        startAngle - pi / 2 + (endAngle - startAngle) * activeFraction;
    final Offset thumbOffset = angleToPoint(thumbAngle, center, radius);
    canvas.drawCircle(thumbOffset, theme.thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant CircularSliderPainter oldDelegate) {
    return activeFraction != oldDelegate.activeFraction ||
        startAngle != oldDelegate.startAngle ||
        endAngle != oldDelegate.endAngle ||
        theme != oldDelegate.theme ||
        disabled != oldDelegate.disabled ||
        radius != oldDelegate.radius;
  }
}
