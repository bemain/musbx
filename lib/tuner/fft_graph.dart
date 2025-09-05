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

  final List<RecordingData> data;

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
    this.minBinIndex = 0,
    this.maxBinIndex = 255,
  });

  final List<RecordingData> data;

  /// Averaged FFT data.
  late final List<double> dataChunks = _getDataChunks();

  final FftGraphStyle style;

  final double audioScale;

  /// Minimum bin index for FFT data.
  final int minBinIndex;

  /// Maximum bin index for FFT data.
  final int maxBinIndex;

  /// Process the FFT data and calculate averages.
  ///
  /// This is an O(n) operation, where n is the length of the FFT data.
  ///
  /// The buffer is divided into `barCount` chunks, and for each chunk the
  /// average of the wave data is calculated and stored in the buffer.
  List<double> _getDataChunks() {
    final barCount = maxBinIndex - minBinIndex;
    final range = maxBinIndex - minBinIndex + 1;
    final chunkSize = range / barCount;

    List<double> averages = [];

    if (data.isEmpty) return [];

    for (var i = 0; i < barCount; i++) {
      var sum = 0.0;
      var count = 0;

      // Calculate chunk boundaries
      final startIdx = (i * chunkSize + minBinIndex).floor();
      final endIdx = ((i + 1) * chunkSize + minBinIndex).ceil();

      // Ensure we don't exceed maxIndex
      final effectiveEndIdx = endIdx.clamp(0, maxBinIndex + 1);

      for (var j = startIdx; j < effectiveEndIdx; j++) {
        sum += data.last.fft[j];
        count++;
      }

      // Store the average for this chunk
      averages.add(count > 0 ? sum / count : 0.0);
    }
    return averages;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = style.barColor;

    if (dataChunks.isEmpty) return;

    // Draw the bars
    final barCount = maxBinIndex - minBinIndex;
    final barWidth = size.width / barCount;
    for (var i = 0; i < barCount; i++) {
      final value = dataChunks[i];
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
