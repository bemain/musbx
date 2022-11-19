import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider/painter.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider/utils.dart';

enum DraggingMode {
  none,
  along,
  inside;
}

class CircularSlider extends StatefulWidget {
  const CircularSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.radius = 50,
    this.startAngle = -2.0,
    this.theme,
    this.endAngle = 2.0,
  });

  final double value;
  final double min;
  final double max;
  final void Function(double value)? onChanged;

  final SliderThemeData? theme;

  final double radius;
  final double startAngle;
  final double endAngle;

  @override
  State<StatefulWidget> createState() => CircularSliderState();
}

class CircularSliderState extends State<CircularSlider> {
  DraggingMode dragging = DraggingMode.none;

  late final Offset center = Offset(widget.radius, widget.radius);
  late CircularSliderPainter painter;
  SliderThemeData? theme;

  double get activeFraction =>
      (widget.value - widget.min) / (widget.max - widget.min);

  @override
  Widget build(BuildContext context) {
    theme ??= widget.theme ?? Theme.of(context).sliderTheme;

    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: GestureDetector(
        onPanDown: (details) {
          final double thumbAngle = widget.startAngle -
              pi / 2 +
              (widget.endAngle - widget.startAngle) * activeFraction;

          final Offset thumbOffset =
              angleToPoint(thumbAngle, center, widget.radius);
          if (isPointAlongCircle(
                details.localPosition,
                center,
                widget.radius,
                16.0,
              ) ||
              isPointInsideCircle(details.localPosition, thumbOffset, 10)) {
            dragging = DraggingMode.along;
            onPan(details.localPosition);
          }
        },
        onPanUpdate: (DragUpdateDetails details) {
          print(details.localPosition);
          if (dragging == DraggingMode.along) {
            onPan(details.localPosition);
          }
        },
        onPanEnd: (details) {
          dragging = DraggingMode.none;
        },
        onPanCancel: () {
          dragging = DraggingMode.none;
        },
        child: CustomPaint(
          painter: CircularSliderPainter(
            theme: theme,
            activeFraction: activeFraction,
            startAngle: widget.startAngle,
            endAngle: widget.endAngle,
          ),
          size: Size(widget.radius * 2, widget.radius * 2),
        ),
      ),
    );
  }

  void onPan(Offset position) {
    double angle = pointToAngle(position, center);
    angle = angle.clamp(widget.startAngle, widget.endAngle);
    double fraction =
        (angle - widget.startAngle) / (widget.endAngle - widget.startAngle);
    double newValue = fraction * (widget.max - widget.min) + widget.min;
    widget.onChanged?.call(newValue);
  }
}
