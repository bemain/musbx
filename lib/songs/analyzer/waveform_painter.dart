import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';

/// Paints the stretch of a waveform around [position], with a marker at the
/// centre showing where playback is.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.waveform,
    required this.position,
    required this.duration,
    required this.style,
    this.padding = 3.0,
    this.markerColor = Colors.black,
    this.markerWidth = 2.0,
    this.amplitude = 1.0,
    this.waveformPixelsPerStep = 12.0,
  });

  /// The waveform of the whole song.
  final Waveform waveform;

  /// Where playback is, drawn at the centre.
  final Duration position;

  /// How much of the song to fit across the canvas.
  final Duration duration;

  final PositionSliderStyle style;

  /// How much the waveform is scaled vertically.
  final double amplitude;

  /// The number of waveform pixels per step.
  /// A smaller value gives greater accuracy.
  final double waveformPixelsPerStep;

  /// The number of empty pixels between each step.
  final double padding;

  /// The colour of the marker showing [position].
  final Color markerColor;

  /// The width of the marker showing [position].
  final double markerWidth;

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
    final Path waveformPath = Path();
    for (
      var i = sampleStart.toDouble();
      i <= waveformPixelsPerWindow + 1.0;
      i += waveformPixelsPerStep
    ) {
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
      waveformPath.addRRect(rrect);
    }

    final Path activeArea = Path()
      ..addRect(Rect.fromLTRB(-100, 0, width / 2, height));

    canvas.drawPath(
      Path.combine(PathOperation.intersect, waveformPath, activeArea),
      Paint()..color = style.activeTrackColor,
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, waveformPath, activeArea),
      Paint()..color = style.inactiveTrackColor,
    );

    canvas.drawLine(
      Offset(width / 2, height),
      Offset(width / 2, 0),
      Paint()
        ..color = markerColor
        ..strokeWidth = markerWidth,
    );
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return true;
  }

  /// Map a raw waveform sample onto a y coordinate on a canvas [height] tall.
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
