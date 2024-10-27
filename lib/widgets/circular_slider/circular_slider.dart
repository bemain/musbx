import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/widgets/circular_slider/painter.dart';
import 'package:musbx/widgets/circular_slider/utils.dart';
import 'package:musbx/widgets/circular_slider/theme.dart';
import 'package:musbx/widgets/circular_slider/custom_pan_gesture_recognizer.dart';

enum DraggingMode {
  none,
  along,
  inside;
}

class CircularSlider extends StatefulWidget {
  /// A circular slider. Similar to [Slider], but drawn as a circle sector.
  ///
  /// If the thumb is being dragged, and the distance between where the user is
  /// touching the screen and the track is larger than [continuousSelectionDistance],
  /// continuous selection is enabled, offering greater accuracy.
  const CircularSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.child,
    this.min = 0.0,
    this.max = 1.0,
    this.divisionValues,
    this.outerRadius = 50,
    this.startAngle = -2.0,
    this.endAngle = 2.0,
    this.touchWidth = 32.0,
    this.continuousSelectionDistance = 16.0,
  });

  /// The currently selected value for this slider.
  ///
  /// The slider's thumb is drawn at a position that corresponds to this value.
  final double value;

  /// The minimum value the user can select.
  ///
  /// Defaults to 0.0. Must be less than or equal to [max].
  final double min;

  /// The maximum value the user can select.
  ///
  /// Defaults to 1.0. Must be greater than or equal to [min].
  final double max;

  /// Called during a drag when the user is selecting a new value for the slider
  /// by dragging.
  ///
  /// The slider passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the slider with the new
  /// value.
  ///
  /// If null, the slider will be displayed as disabled.
  final void Function(double value)? onChanged;

  /// Called when the user starts selecting a new value for the slider.
  ///
  /// This callback shouldn't be used to update the slider [value] (use
  /// [onChanged] for that), but rather to be notified when the user has started
  /// selecting a new value by starting a drag or with a tap.
  ///
  /// The value passed will be the last [value] that the slider had before the
  /// change began.
  final void Function()? onChangeStart;

  /// Called when the user is done selecting a new value for the slider.
  ///
  /// This callback shouldn't be used to update the slider [value] (use
  /// [onChanged] for that), but rather to know when the user has completed
  /// selecting a new [value] by ending a drag or a click.
  final void Function()? onChangeEnd;

  /// The values on the slider where divisions are placed.
  ///
  /// If null, the slider is continuous.
  final List<double>? divisionValues;

  /// Widget displayed in the center of the slider.
  final Widget? child;

  /// The radius of the slider, measured from the outside of the track touch area.
  final double outerRadius;

  /// The angle that the circle sector starts at.
  final double startAngle;

  /// The angle that the circle sector ends at.
  final double endAngle;

  /// Width of the touch area around the circle sector.
  final double touchWidth;

  /// The minimum distance from the where the user is dragging to the track that enables continuous selection.
  final double continuousSelectionDistance;

  @override
  State<StatefulWidget> createState() => CircularSliderState();
}

class CircularSliderState extends State<CircularSlider> {
  bool dragging = false;

  /// The fraction of the circle sector that is active,
  /// meaning it is between [min] and [value]
  double get activeFraction =>
      (widget.value - widget.min) / (widget.max - widget.min);

  /// The radius of the circle sector, measured from the center of the track.
  double get radius => widget.outerRadius - widget.touchWidth / 2;

  /// The size that the slider takes up.
  Size get size => Size.square(widget.outerRadius * 2);

  /// The center of the slider.
  Offset get center => size.center(Offset.zero);

  @override
  Widget build(BuildContext context) {
    return buildCustomPanGestureDetector(
      recognizer: CustomPanGestureRecognizer(
        onPanDown: onPanDown,
        onPanUpdate: (PointerMoveEvent event) {
          if (dragging) {
            onPan(event.position);
          }
        },
        onPanEnd: (PointerUpEvent event) {
          setState(() {
            dragging = false;
          });
          widget.onChangeEnd?.call();
        },
        onPanCancel: (PointerCancelEvent event) {
          setState(() {
            dragging = false;
          });
        },
      ),
      child: CustomPaint(
        painter: CircularSliderPainter(
          theme: CircularSliderTheme.fromThemes(
            Theme.of(context),
            SliderTheme.of(context),
          ),
          radius: radius,
          activeFraction: activeFraction,
          startAngle: widget.startAngle,
          endAngle: widget.endAngle,
          divisions: widget.divisionValues
              ?.map((value) => (value - widget.min) / (widget.max - widget.min))
              .toList(),
          dragging: dragging,
          disabled: widget.onChanged == null,
        ),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Center(child: widget.child),
        ),
      ),
    );
  }

  /// If [event] is along the slider or inside the thumb, handle pan and return true.
  /// Otherwise, return false,
  bool onPanDown(PointerEvent event) {
    if (widget.onChanged == null) return false;

    final double thumbAngle = widget.startAngle -
        pi / 2 +
        (widget.endAngle - widget.startAngle) * activeFraction;
    final Offset thumbOffset = angleToPoint(thumbAngle, center, radius);

    final double eventAngle =
        pointToAngle(globalToLocal(event.position), center);

    if ((isPointAlongCircle(
              globalToLocal(event.position),
              center,
              radius,
              widget.touchWidth,
            ) &&
            eventAngle > widget.startAngle &&
            eventAngle < widget.endAngle) ||
        isPointInsideCircle(globalToLocal(event.position), thumbOffset, 10)) {
      dragging = true;
      widget.onChangeStart?.call();
      onPan(event.position);
      return true;
    }
    return false;
  }

  /// Calculate the new value and invoke [onChanged] callback.
  void onPan(Offset globalPosition) {
    Offset localPosition = globalToLocal(globalPosition);
    double angle = pointToAngle(localPosition, center)
        .clamp(widget.startAngle, widget.endAngle);
    double fraction =
        (angle - widget.startAngle) / (widget.endAngle - widget.startAngle);
    double newValue = fraction * (widget.max - widget.min) + widget.min;

    if (widget.divisionValues != null &&
        (localPosition - center).distance <
            radius + widget.continuousSelectionDistance) {
      // Snap value to nearest division
      double nearestDivisionValue = widget.divisionValues![0];
      for (double divisionValue in widget.divisionValues!) {
        if ((newValue - divisionValue).abs() <
            (newValue - nearestDivisionValue).abs()) {
          nearestDivisionValue = divisionValue;
        }
      }
      newValue = nearestDivisionValue;
    }

    widget.onChanged?.call(newValue);
  }

  /// Convert global [position] to local coordinate space.
  Offset globalToLocal(Offset position) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(position);
  }
}
