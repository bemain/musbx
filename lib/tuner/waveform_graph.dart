import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class WaveformGraphStyle {
  /// The width of the bars.
  final double barWidth;

  /// The number of empty pixels between each bar.
  final double barPadding;

  /// The radius used for the [RRect] bars.
  final Radius barRadius;

  /// The color of the bars.
  final Color barColor;

  double get effectiveBarWidth => barWidth + barPadding;

  /// Create [WaveformGraphStyle] based on the given [theme].
  WaveformGraphStyle.fromTheme(
    ThemeData theme, {
    this.barWidth = 4.0,
    this.barPadding = 3.0,
    this.barRadius = const Radius.circular(4.0),
  }) : barColor = theme.colorScheme.primary;
}

/// Widget to draw the wave data.
class WaveformGraph extends StatelessWidget {
  const WaveformGraph({super.key, required this.data});

  final Float32List data;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: WavePainter(
          data: data,
          style: WaveformGraphStyle.fromTheme(Theme.of(context)),
          audioScale: 8.0,
        ),
        size: const Size(double.infinity, 64),
      ),
    );
  }
}

/// Custom painter to draw the wave data.
class WavePainter extends CustomPainter {
  ///
  WavePainter({
    required this.data,
    required this.style,
    this.audioScale = 1.0,
  });

  /// The wave data to draw.
  final Float32List data;

  final WaveformGraphStyle style;

  final double audioScale;

  /// Calculates the effective number of bars that can be drawn
  /// given the current canvas width and the bar width.
  int _calculateEffectiveBarCount(double width) {
    return (width / style.effectiveBarWidth).floor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveBarCount = min(
      data.length,
      _calculateEffectiveBarCount(size.width),
    );

    final paint = Paint()..color = style.barColor;

    // Draw the bars
    for (var i = 0; i < effectiveBarCount; i++) {
      final double value = data[data.length - effectiveBarCount + i];
      final double barHeight = size.height * value * 2 * audioScale;
      final double barX = i * style.effectiveBarWidth;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barX,
            (size.height - barHeight) * 0.5,
            style.barWidth,
            barHeight,
          ),
          style.barRadius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return true;
  }
}
