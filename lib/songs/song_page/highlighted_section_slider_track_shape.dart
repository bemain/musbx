import 'dart:math';

import 'package:flutter/material.dart';

class HighlightedSectionSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  /// Highlights a section of a Slider's track.
  HighlightedSectionSliderTrackShape({
    required this.highlightStart,
    required this.highlightEnd,
    required this.nonHighlightColor,
    required this.disabledNonHighlightColor,
    this.stopIndicatorRadius = 2.0,
    this.highlightGap = 4.0,
  });

  /// Where to begin the highlight, as a fraction of the track's length.
  ///
  /// Must be between 0 and 1, and smaller than [highlightEnd]
  final double highlightStart;

  /// Where to end the highlight, as a fraction of the track's length.
  ///
  /// Must be between 0 and 1, and greater than [highlightStart]
  final double highlightEnd;

  /// The color used for the part of the track that is not highlighted.
  final Color nonHighlightColor;

  /// The color used for the part of the track that is not highlighted when the slider is disabled.
  final Color disabledNonHighlightColor;

  final double stopIndicatorRadius;

  final double highlightGap;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    assert(sliderTheme.trackGap != null);
    assert(!sliderTheme.trackGap!.isNegative);
    // If the slider [SliderThemeData.trackHeight] is less than or equal to 0,
    // then it makes no difference whether the track is painted or not,
    // therefore the painting can be a no-op.
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

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

    double highlightLeft = trackRect.left + trackRect.width * highlightStart;
    double highlightRight = trackRect.left + trackRect.width * highlightEnd;

    final ColorTween activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );

    final ColorTween outsideTrackColorTween = ColorTween(
      begin: nonHighlightColor,
      end: disabledNonHighlightColor,
    );

    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    final Paint highlightLeftPaint = activePaint;
    final Paint highlightRightPaint = inactivePaint;

    final Paint outsidePaint = Paint()
      ..color = outsideTrackColorTween.evaluate(enableAnimation)!;

    final Radius trackCornerRadius = Radius.circular(
      trackRect.shortestSide / 2,
    );
    const Radius trackInsideCornerRadius = Radius.circular(2.0);

    // Gap, starting from the middle of the thumb.
    final double trackGap = sliderTheme.trackGap!;

    final double drawThreshold = sliderTheme.trackHeight! / 2;
    final double insideDrawThreshold = trackGap / 2;
    final bool drawLeftHighlight =
        thumbCenter.dx >
        max(
          trackRect.left + drawThreshold,
          highlightLeft + insideDrawThreshold,
        );
    final bool drawRightHighlight =
        thumbCenter.dx <
        min(
          trackRect.right - drawThreshold,
          highlightRight - insideDrawThreshold,
        );
    final bool drawLeftOutside =
        highlightLeft >
        (trackRect.left + max(insideDrawThreshold, drawThreshold));
    final bool drawRightOutside =
        highlightRight <
        (trackRect.right - max(insideDrawThreshold, drawThreshold));

    final RRect trackRRect = RRect.fromRectAndCorners(
      trackRect,
      topLeft: trackCornerRadius,
      bottomLeft: trackCornerRadius,
      topRight: trackCornerRadius,
      bottomRight: trackCornerRadius,
    );

    final RRect highlightLeftRRect = RRect.fromLTRBAndCorners(
      highlightLeft,
      trackRect.top,
      max(highlightLeft, thumbCenter.dx - trackGap),
      trackRect.bottom,
      topLeft: drawLeftOutside ? trackInsideCornerRadius : trackCornerRadius,
      bottomLeft: drawLeftOutside
          ? trackInsideCornerRadius
          : trackCornerRadius,
      topRight: trackInsideCornerRadius,
      bottomRight: trackInsideCornerRadius,
    );

    final RRect highlightRightRRect = RRect.fromLTRBAndCorners(
      thumbCenter.dx + trackGap,
      trackRect.top,
      highlightRight,
      trackRect.bottom,
      topRight: drawRightOutside ? trackInsideCornerRadius : trackCornerRadius,
      bottomRight: drawRightOutside
          ? trackInsideCornerRadius
          : trackCornerRadius,
      topLeft: trackInsideCornerRadius,
      bottomLeft: trackInsideCornerRadius,
    );

    final RRect outsideLeftRRect = RRect.fromLTRBAndCorners(
      trackRect.left,
      trackRect.top,
      max(trackRect.left, highlightLeft - highlightGap),
      trackRect.bottom,
      topLeft: trackCornerRadius,
      bottomLeft: trackCornerRadius,
      topRight: trackInsideCornerRadius,
      bottomRight: trackInsideCornerRadius,
    );

    final RRect outsideRightRRect = RRect.fromLTRBAndCorners(
      min(trackRect.right, highlightRight + highlightGap),
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
      topRight: trackCornerRadius,
      bottomRight: trackCornerRadius,
      topLeft: trackInsideCornerRadius,
      bottomLeft: trackInsideCornerRadius,
    );

    context.canvas
      ..save()
      ..clipRRect(trackRRect);

    if (drawLeftHighlight) {
      context.canvas.drawRRect(highlightLeftRRect, highlightLeftPaint);
    }
    if (drawRightHighlight) {
      context.canvas.drawRRect(highlightRightRRect, highlightRightPaint);
    }
    if (drawLeftOutside) {
      context.canvas.drawRRect(outsideLeftRRect, outsidePaint);
    }
    if (drawRightOutside) {
      context.canvas.drawRRect(outsideRightRRect, outsidePaint);
    }
    context.canvas.restore();

    final double stopIndicatorTrailingSpace = sliderTheme.trackHeight! / 2;
    final Offset stopIndicatorOffset = Offset(
      highlightRight - stopIndicatorTrailingSpace,
      trackRect.center.dy,
    );

    final bool showStopIndicator = thumbCenter.dx < stopIndicatorOffset.dx;
    if (showStopIndicator && !isDiscrete) {
      final Rect stopIndicatorRect = Rect.fromCircle(
        center: stopIndicatorOffset,
        radius: stopIndicatorRadius,
      );
      context.canvas.drawCircle(
        stopIndicatorRect.center,
        stopIndicatorRadius,
        highlightLeftPaint,
      );
    }
  }

  @override
  bool get isRounded => true;
}
