import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.waveform,
    required this.start,
    required this.duration,
    this.padding = 2.0,
    this.color = Colors.blue,
    this.amplitude = 1.0,
    this.waveformPixelsPerStep = 16.0,
  });

  final Waveform waveform;

  final Duration start;
  final Duration duration;

  final double amplitude;

  /// The number of waveform pixels per step.
  /// A smaller value gives greater accuracy.
  final double waveformPixelsPerStep;

  /// The number of empty pixels between each step.
  final double padding;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    final double width = size.width;
    final double height = size.height;

    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;

    final double strokeWidth =
        width / waveformPixelsPerWindow * waveformPixelsPerStep - padding;

    final Paint wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final x = i / waveformPixelsPerDevicePixel;
      final minY = normalize(waveform.getPixelMin(sampleIdx), height);
      final maxY = normalize(waveform.getPixelMax(sampleIdx), height);
      canvas.drawLine(
        Offset(x + strokeWidth / 2, max(strokeWidth * 0.75, minY)),
        Offset(x + strokeWidth / 2, min(height - strokeWidth * 0.75, maxY)),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return false;
  }

  double normalize(int s, double height) {
    if (waveform.flags == 0) {
      final y = 32768 + (amplitude * s).clamp(-32768.0, 32767.0).toDouble();
      return height - 1 - y * height / 65536;
    } else {
      final y = 128 + (amplitude * s).clamp(-128.0, 127.0).toDouble();
      return height - 1 - y * height / 256;
    }
  }
}
