import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/tuner/tuner.dart';

class WaveformGraphStyle {
  /// The number of empty pixels between each bar.
  final double barPadding;

  /// The radius used for the [RRect] bars.
  final Radius barRadius;

  /// The color of the bars.
  final Color barColor;

  WaveformGraphStyle({
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
      barPadding: barPadding ?? this.barPadding,
      barRadius: barRadius ?? this.barRadius,
      barColor: barColor ?? this.barColor,
    );
  }

  /// Create [WaveformGraphStyle] based on the given [theme].
  WaveformGraphStyle.fromTheme(
    ThemeData theme, {
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
    this.chunks = 64,
    this.audioScale = 1.0,
  });

  /// The wave data to draw.
  final List<RecordingData> data;

  /// Averaged wave data.
  late final List<double> dataChunks = _getDataChunks();

  final WaveformGraphStyle style;

  /// The size of the chunks that the data is grouped into.
  final int chunkSize;

  /// The number of chunks to display.
  final int chunks;

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

  @override
  void paint(Canvas canvas, Size size) {
    final double effectiveBarWidth = size.width / chunks;
    final effectiveBarCount = min(dataChunks.length, chunks);

    final paint = Paint()..color = style.barColor;

    // Draw the bars
    for (var i = 0; i < effectiveBarCount; i++) {
      final double value =
          dataChunks[dataChunks.length - effectiveBarCount + i];
      final double barHeight = size.height * value * 2 * audioScale;
      final double barX = size.width - i * effectiveBarWidth;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barX + style.barPadding / 2,
            (size.height - barHeight) * 0.5,
            effectiveBarWidth - style.barPadding,
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
