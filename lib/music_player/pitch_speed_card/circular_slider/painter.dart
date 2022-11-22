import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider/utils.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider/theme.dart';

class CircularSliderPainter extends CustomPainter {
  CircularSliderPainter({
    required this.activeFraction,
    required this.startAngle,
    required this.endAngle,
    required this.radius,
    this.disabled = false,
    required this.theme,
    this.divisions,
  });

  /// The angle that the circle sector starts at.
  final double startAngle;

  /// The angle that the circle sector ends at.
  final double endAngle;

  /// The radius of the circle sector.
  final double radius;

  /// The fraction of the circle sector that is active.
  final double activeFraction;

  /// If true, the slider will be displayed as disabled.
  final bool disabled;

  /// The theme specifying colors for the slider.
  final CircularSliderTheme theme;

  /// The number of discrete divisions, if any.
  final int? divisions;

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

    final double thumbAngle =
        startAngle - pi / 2 + (endAngle - startAngle) * activeFraction;

    // Draw tick marks
    if (divisions != null) {
      final Paint activeTickMarkPaint = Paint()
        ..color = disabled
            ? theme.disabledActiveTickMarkColor
            : theme.activeTickMarkColor;
      final Paint inactiveTickMarkPaint = Paint()
        ..color = disabled
            ? theme.disabledInactiveTickMarkColor
            : theme.inactiveTickMarkColor;
      for (int i = 0; i <= divisions!; i++) {
        double angle =
            startAngle - pi / 2 + (endAngle - startAngle) * (i / divisions!);
        Offset offset = angleToPoint(angle, center, radius);
        canvas.drawCircle(offset, theme.trackHeight / 4,
            (angle < thumbAngle) ? activeTickMarkPaint : inactiveTickMarkPaint);
      }
    }

    // Draw thumb
    final Paint thumbPaint = Paint()
      ..color = disabled ? theme.disabledThumbColor : theme.thumbColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

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
        radius != oldDelegate.radius ||
        divisions != oldDelegate.divisions;
  }
}
