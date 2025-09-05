import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/tuner/tuner.dart';

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

  WaveformGraphStyle({
    this.barWidth = 4.0,
    this.barPadding = 3.0,
    this.barRadius = const Radius.circular(4.0),
    this.barColor = Colors.blue,
  });

  /// Returns a copy of this style with the given fields replaced.
  WaveformGraphStyle copyWith({
    double? barWidth,
    double? barPadding,
    Radius? barRadius,
    Color? barColor,
  }) {
    return WaveformGraphStyle(
      barWidth: barWidth ?? this.barWidth,
      barPadding: barPadding ?? this.barPadding,
      barRadius: barRadius ?? this.barRadius,
      barColor: barColor ?? this.barColor,
    );
  }

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

  final List<RecordingData> data;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: WavePainter(
          data: data,
          style: WaveformGraphStyle.fromTheme(Theme.of(context)),
          audioScale: 48.0,
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
    this.chunkSize = 128,
    this.audioScale = 1.0,
  });

  /// The wave data to draw.
  final List<RecordingData> data;

  /// Averaged wave data.
  late final List<double> dataChunks = _getDataChunks();

  final WaveformGraphStyle style;

  /// The size of the chunks that the data is grouped into.
  final int chunkSize;

  final double audioScale;

  /// Process wave [data] by splitting it into chunks.
  List<double> _getDataChunks() {
    List<double> averages = [];
    List<double> chunk = [];
    for (var dataEntry in data) {
      chunk.addAll(dataEntry.wave);
      while (chunk.length >= chunkSize) {
        final double sum = chunk
            .sublist(0, chunkSize)
            .fold(0.0, (a, b) => a + b);
        averages.add(sum / chunkSize);
        chunk = chunk.sublist(chunkSize);
      }
    }

    if (chunk.isNotEmpty) {
      // Add remaining
      averages.add(chunk.fold(0.0, (a, b) => a + b) / chunk.length);
    }
    return averages.reversed.toList();
  }

  /// Calculates the effective number of bars that can be drawn
  /// given the current canvas width and the bar width.
  int _calculateEffectiveBarCount(double width) {
    return (width / style.effectiveBarWidth).floor() + 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveBarCount = min(
      dataChunks.length,
      _calculateEffectiveBarCount(size.width),
    );

    final paint = Paint()..color = style.barColor;

    // Draw the bars
    for (var i = 0; i < effectiveBarCount; i++) {
      final double value =
          dataChunks[dataChunks.length - effectiveBarCount + i];
      final double barHeight = size.height * value * 2 * audioScale;
      final double barX = size.width - i * style.effectiveBarWidth;

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
