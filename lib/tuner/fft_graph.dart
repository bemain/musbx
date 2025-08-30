import 'dart:typed_data' show Float32List;

import 'package:flutter/material.dart';
import 'package:musbx/tuner/tuner.dart';

class FftGraphStyle {
  /// The radius used for the [RRect] bars.
  final Radius barRadius;

  /// The color of the bars.
  final Color barColor;

  /// Create [WaveformStyle] based on the given [theme].
  FftGraphStyle.fromTheme(
    ThemeData theme, {
    this.barRadius = const Radius.circular(4.0),
  }) : barColor = theme.colorScheme.primary;
}

/// Widget to draw the FFT data.
class FftGraph extends StatelessWidget {
  /// Constructor.
  const FftGraph({
    super.key,
    required this.data,
  });

  final Float32List data;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: FftPainter(
          data: data,
          style: FftGraphStyle.fromTheme(Theme.of(context)),
        ),
        size: const Size(double.infinity, 64),
      ),
    );
  }
}

/// Custom painter to draw the FFT data.
class FftPainter extends CustomPainter {
  ///
  FftPainter({
    required this.data,
    required this.style,
    this.audioScale = 1.0,
  });

  final Float32List data;

  final FftGraphStyle style;

  final double audioScale;

  @override
  void paint(Canvas canvas, Size size) {
    // params.dataManager.ensureCapacity(effectiveBarCount);

    final paint = Paint()..color = style.barColor;

    // Draw the bars
    final barCount = Tuner.fftMaxBinIndex - Tuner.fftMinBinIndex;
    final barWidth = size.width / barCount;
    for (var i = 0; i < barCount; i++) {
      final value = data[i];
      final barHeight = size.height * value * audioScale;
      final barX = i * barWidth;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barX,
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          style.barRadius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FftPainter oldDelegate) {
    return true;
  }
}
