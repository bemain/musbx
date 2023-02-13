import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class EqualizerOverlayPainter extends CustomPainter {
  /// Paints an overlay onto a set of sliders used to control the gain on
  /// Equalizer's bands.
  ///
  /// Connects the thumbs of the sliders using a line, and fills the area
  /// between the line and the center with a gradient.
  EqualizerOverlayPainter({
    required this.parameters,
    required this.lineColor,
    this.lineWidth = 6.0,
    this.fillEnabled = true,
    Color? fillColor,
  }) : fillColor = fillColor ?? lineColor;

  /// The Equalizer's parameters.
  final AndroidEqualizerParameters? parameters;

  /// The color of the line connecting the thumbs.
  final Color lineColor;

  /// The width of the line connecting the thumbs.
  final double lineWidth;

  final bool fillEnabled;

  /// The color used to generate the gradient that is applied to the fill between
  /// the line connecting the thumbs and the center.
  ///
  /// Default to [lineColor].
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (parameters == null) {
      // Assume all the bands have a gain of 0.
      // Draw a disabled line at the center of the overlay
      canvas.drawLine(
        Offset(size.width * (1 - 0.5 / 5), size.height / 2),
        Offset(size.width * 0.5 / 5, size.height / 2),
        Paint()
          ..strokeWidth = lineWidth
          ..color = lineColor,
      );
      return;
    }

    /// How much the [Slider]'s track is padded
    const double sliderTrackPadding = 24;

    /// The actual height of the [Slider]'s track (and thus the maximum height of the overlay)
    final double actualHeight = size.height - sliderTrackPadding * 2;

    // Paints
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = lineWidth
      ..color = lineColor;
    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    // Generate spline points
    List<Offset> controlPoints = List.generate(
      parameters!.bands.length,
      (index) {
        AndroidEqualizerBand band = parameters!.bands[index];
        double decibelFraction = (band.gain - parameters!.minDecibels) /
            (parameters!.maxDecibels - parameters!.minDecibels);

        return Offset(size.width * (index + 0.5) / parameters!.bands.length,
            sliderTrackPadding + actualHeight * (1 - decibelFraction));
      },
    );

    final CatmullRomSpline spline = CatmullRomSpline(controlPoints);
    final List<Offset> splinePoints =
        spline.generateSamples(tolerance: 1).map((e) => e.value).toList();
    final Path splinePath = Path()..addPolygon(splinePoints, false);

    if (fillEnabled) {
      // Fill
      Shader fillShader({Alignment? start, Alignment? end}) => LinearGradient(
            begin: start ?? Alignment.center,
            end: end ?? Alignment.bottomCenter,
            stops: const [0, 0.2, 1],
            colors: [
              fillColor.withOpacity(0),
              fillColor.withOpacity(0.3),
              fillColor.withOpacity(1),
            ],
          ).createShader(Offset.zero & size);

      Path fillPath = Path()
        ..addPolygon(splinePoints, false)
        ..lineTo(
            size.width * (1 - 0.5 / parameters!.bands.length), size.height / 2)
        ..lineTo(size.width * 0.5 / parameters!.bands.length, size.height / 2);

      // Draw fill below line
      fillPaint.shader = fillShader(end: Alignment.bottomCenter);
      canvas.drawPath(fillPath, fillPaint);
      // Draw fill above line
      fillPaint.shader = fillShader(end: Alignment.topCenter);
      canvas.drawPath(fillPath, fillPaint);
    }
    // Draw line
    canvas.drawPath(splinePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant EqualizerOverlayPainter oldDelegate) {
    return parameters != oldDelegate.parameters ||
        lineColor != oldDelegate.lineColor ||
        lineWidth != oldDelegate.lineWidth ||
        fillEnabled != oldDelegate.fillEnabled ||
        fillColor != oldDelegate.fillColor;
  }
}
