import 'dart:math';

import 'package:flutter/material.dart';

class HighlightedSectionSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  /// Highlights a section of a Slider's track.
  HighlightedSectionSliderTrackShape({
    required this.highlightStart,
    required this.highlightEnd,
    required this.activeHighlightColor,
    required this.inactiveHighlightColor,
  });

  /// Where to begin the highlight, as a fraction of the track's length.
  ///
  /// Must be between 0 and 1, and smaller than [highlightStart]
  final double highlightStart;

  /// Where to end the highlight, as a fraction of the track's length.
  ///
  /// Must be between 0 and 1, and greater than [highlightEnd]
  final double highlightEnd;

  /// The color used for the active part of the highlighted section of the track.
  final Color activeHighlightColor;

  /// The color used for the inactive part of the highlighted section of the track.
  final Color inactiveHighlightColor;

  @override
  void paint(PaintingContext context, Offset offset,
      {required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required Animation<double> enableAnimation,
      required Offset thumbCenter,
      bool isEnabled = false,
      bool isDiscrete = false,
      required TextDirection textDirection}) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    assert(sliderTheme.trackHeight != null && sliderTheme.trackHeight! > 0);

    assert(highlightStart >= 0 && highlightStart <= 1);
    assert(highlightEnd >= 0 && highlightEnd <= 1);
    assert(highlightStart <= highlightEnd);

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    Offset highlightStartOffset =
        Offset(trackRect.left + trackRect.width * highlightStart, 0);
    Offset highlightEndOffset =
        Offset(trackRect.left + trackRect.width * highlightEnd, 0);

    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);

    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    final Paint activeHighlightPaint = Paint()..color = activeHighlightColor;
    final Paint inactiveHighlightPaint = Paint()
      ..color = inactiveHighlightColor;

    final Radius inactiveTrackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius = Radius.circular(trackRect.height / 2 + 1);

    // DRAW HIGHLIGHT
    // Active part
    final RRect activeHighlightRRect = RRect.fromLTRBAndCorners(
      highlightStartOffset.dx,
      trackRect.top - 1,
      min(thumbCenter.dx, highlightEndOffset.dx),
      trackRect.bottom + 1,
      topLeft: activeTrackRadius,
      bottomLeft: activeTrackRadius,
    );
    context.canvas.drawRRect(
      activeHighlightRRect,
      activeHighlightPaint,
    );

    // Inactive part
    final RRect inactiveHighlightRRect = RRect.fromLTRBAndCorners(
      max(thumbCenter.dx, highlightStartOffset.dx),
      trackRect.top,
      highlightEndOffset.dx,
      trackRect.bottom,
      topRight: inactiveTrackRadius,
      bottomRight: inactiveTrackRadius,
    );
    context.canvas.drawRRect(
      inactiveHighlightRRect,
      inactiveHighlightPaint,
    );

    // Draw regular slider track
    context.canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()
          ..addRRect(
            RRect.fromLTRBAndCorners(
              trackRect.left,
              trackRect.top - 1,
              highlightStartOffset.dx + activeTrackRadius.x,
              trackRect.bottom + 1,
              topLeft: activeTrackRadius,
              bottomLeft: activeTrackRadius,
            ),
          ),
        Path()..addRRect(activeHighlightRRect),
      ),
      activePaint,
    );
    context.canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()
          ..addRRect(
            RRect.fromLTRBAndCorners(
              highlightEndOffset.dx - inactiveTrackRadius.x,
              trackRect.top,
              trackRect.right,
              trackRect.bottom,
              topRight: inactiveTrackRadius,
              bottomRight: inactiveTrackRadius,
            ),
          ),
        Path()..addRRect(inactiveHighlightRRect),
      ),
      inactivePaint,
    );
  }
}
