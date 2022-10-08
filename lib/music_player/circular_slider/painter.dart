import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/circular_slider/utils.dart';

class CircularSliderPainter extends CustomPainter {
  CircularSliderPainter({
    required this.activeFraction,
    required this.startAngle,
    required this.endAngle,
    this.theme,
  });

  final double startAngle;
  final double endAngle;

  final double activeFraction;
  final SliderThemeData? theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Color activeColor = theme?.activeTrackColor ?? Colors.blue;
    final Color inactiveColor = theme?.inactiveTrackColor ?? Colors.grey;
    final double activeTrackWidth = theme?.trackHeight ?? 8.0;

    Paint activePaint = Paint()
      ..color = activeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeTrackWidth;
    Paint inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = activeTrackWidth / 2;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width / 2, size.height / 2);

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
      ..color = activeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final double thumbAngle =
        startAngle - pi / 2 + (endAngle - startAngle) * activeFraction;
    final Offset thumbOffset = angleToPoint(thumbAngle, center, radius);
    canvas.drawCircle(thumbOffset, 10, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant CircularSliderPainter oldDelegate) {
    return activeFraction != oldDelegate.activeFraction ||
        startAngle != oldDelegate.startAngle ||
        endAngle != oldDelegate.endAngle ||
        theme != oldDelegate.theme;
  }
}
