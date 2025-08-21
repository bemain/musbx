import 'package:flutter/material.dart';
import 'package:musbx/songs/equalizer/equalizer.dart';

class EqualizerOverlayPainter extends CustomPainter {
  /// Paints an overlay onto a set of sliders used to control the gain on
  /// Equalizer's bands.
  ///
  /// Connects the thumbs of the sliders using a line, and fills the area
  /// between the line and the center with a gradient.
  EqualizerOverlayPainter({
    required this.bands,
    required this.lineColor,
    this.lineWidth = 6.0,
    this.fillColor,
  });

  /// The Equalizer's parameters.
  ///
  /// If this is `null`, the sliders are painted as disabled.
  final List<EqualizerBand>? bands;

  /// The color of the line connecting the thumbs.
  final Color lineColor;

  /// The width of the line connecting the thumbs.
  final double lineWidth;

  /// The color used to generate the gradient that is applied to the fill between
  /// the line connecting the thumbs and the center.
  ///
  /// If null, no fill is rendered.
  final Color? fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bands == null) {
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
    const double sliderTrackPadding = 12;

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
      bands!.length,
      (index) {
        EqualizerBand band = bands![index];
        double decibelFraction =
            (band.gain - EqualizerBand.minGain) /
            (EqualizerBand.maxGain - EqualizerBand.minGain);

        return Offset(
          size.width * (index + 0.5) / bands!.length,
          sliderTrackPadding + actualHeight * (1 - decibelFraction),
        );
      },
    );

    final CatmullRomSpline spline = CatmullRomSpline(controlPoints);
    final List<Offset> splinePoints = spline
        .generateSamples(tolerance: 1)
        .map((e) => e.value)
        .toList();
    final Path splinePath = Path()..addPolygon(splinePoints, false);

    if (fillColor != null) {
      // Fill
      Shader fillShader({Alignment? start, Alignment? end}) => LinearGradient(
        begin: start ?? Alignment.center,
        end: end ?? Alignment.bottomCenter,
        stops: const [0, 0.2, 1],
        colors: [
          fillColor!.withAlpha(0x00),
          fillColor!.withAlpha(0x61),
          fillColor!.withAlpha(0xff),
        ],
      ).createShader(Offset.zero & size);

      Path fillPath = Path()
        ..addPolygon(splinePoints, false)
        ..lineTo(size.width * (1 - 0.5 / bands!.length), size.height / 2)
        ..lineTo(size.width * 0.5 / bands!.length, size.height / 2);

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
    return bands != oldDelegate.bands ||
        lineColor != oldDelegate.lineColor ||
        lineWidth != oldDelegate.lineWidth ||
        fillColor != oldDelegate.fillColor;
  }
}
