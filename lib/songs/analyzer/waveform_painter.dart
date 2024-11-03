import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.waveform,
    required this.position,
    required this.duration,
    this.padding = 2.0,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.amplitude = 1.0,
    this.waveformPixelsPerStep = 12.0,
  });

  final Waveform waveform;

  final Duration position;
  final Duration duration;

  final double amplitude;

  /// The number of waveform pixels per step.
  /// A smaller value gives greater accuracy.
  final double waveformPixelsPerStep;

  /// The number of empty pixels between each step.
  final double padding;

  /// The color used for the part of the waveform before [position].
  final Color activeColor;

  /// The color used for the part of the waveform after [position].
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    final Duration start = position - duration * 0.5;

    final double width = size.width;
    final double height = size.height;

    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;
    final double stepWidth =
        waveformPixelsPerStep / waveformPixelsPerDevicePixel;

    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;
    final Path activePath = Path();
    final Path inactivePath = Path();
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final x = i / waveformPixelsPerDevicePixel;
      final minY = normalize(waveform.getPixelMin(sampleIdx), height);
      final maxY = normalize(waveform.getPixelMax(sampleIdx), height);
      final RRect rrect = RRect.fromLTRBR(
        x - stepWidth / 2 + padding / 2,
        max(stepWidth * 0.75, minY),
        x + stepWidth / 2 - padding / 2,
        min(height - stepWidth * 0.75, maxY),
        Radius.circular(stepWidth / 2),
      );
      activePath.addRRect(rrect);
      inactivePath.addRRect(rrect);
    }

    final Path activeArea = Path()
      ..addRect(Rect.fromLTRB(-100, 0, width / 2, height));

    canvas.drawPath(
      Path.combine(PathOperation.intersect, activePath, activeArea),
      Paint()..color = activeColor,
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, inactivePath, activeArea),
      Paint()..color = inactiveColor,
    );
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return true;
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
