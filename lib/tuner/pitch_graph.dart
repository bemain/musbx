import 'dart:math' show max;
import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/tuner/waveform_graph.dart';

class PitchGraphStyle {
  PitchGraphStyle({
    this.continuous = false,
    this.inTuneColor = Colors.green,
    required this.lineColor,
    this.lineWidth = 4.0,
    this.renderTextThreshold = 3,
    this.textStyle,
    this.textPlacement = TextPlacement.relative,
    this.textOffset = 15.0,
  });

  /// Whether to render the frequencies as a continuous line.
  /// Otherwise renders them as points.
  final bool continuous;

  /// The color used for the segment indicating where the frequency is in tune.
  final Color inTuneColor;

  /// The color used when rendering the frequencies.
  final Color lineColor;

  /// The width used when rendering the frequencies.
  final double lineWidth;

  /// The color of the text displaying the note name.
  final TextStyle? textStyle;

  /// Where to place the text.
  final TextPlacement textPlacement;

  /// How much to offset the text in the y-direction.
  ///
  /// Only used if [textPlacement] is [TextPlacement.relative]
  final double textOffset;

  /// The minimum consecutive entries of the same note required before text is rendered.
  final int renderTextThreshold;
}

class PitchGraph extends StatelessWidget {
  /// Graph showing how the tuning of [frequencyHistory] has changed over time.
  const PitchGraph({super.key, required this.data});

  /// The frequencies to display.
  final List<RecordingData> data;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          CustomPaint(
            painter: PitchGraphPainter(
              data: data,
              style: PitchGraphStyle(
                continuous: true,
                lineColor: Theme.of(context).colorScheme.primary,
                textStyle: GoogleFonts.andikaTextTheme(
                  Theme.of(context).textTheme,
                ).bodyMedium,
                inTuneColor: Colors.green.harmonizeWith(
                  Theme.of(context).colorScheme.primary,
                ),
                textPlacement: TextPlacement.top,
              ),
              dataLength: Tuner.bufferLength,
            ),
            size: const Size(double.infinity, 150),
          ),
          CustomPaint(
            painter: WavePainter(
              data: data,
              style: WaveformGraphStyle.fromTheme(Theme.of(context)).copyWith(
                barColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(0x1f),
              ),
              chunks: Tuner.bufferLength * 2,
              audioScale: 48.0,
            ),
            size: const Size(double.infinity, 150),
          ),
        ],
      ),
    );
  }
}

/// Where to place the text displaying the names of the Notes.
enum TextPlacement {
  /// At the top of the graph.
  top,

  /// At the bottom of the graph.
  bottom,

  /// Relative to the note line. Above the line if the frequency is too low and below otherwise.
  relative,
}

class PitchGraphPainter extends CustomPainter {
  /// Paints a line showing the tuning of the frequencies in [frequencyHistory].
  ///
  /// Displays text showing the names of the closest [Pitch]es.
  /// Highlights the section where the tone is in tune in green.
  PitchGraphPainter({
    required this.data,
    required this.style,
    this.dataLength,
  });

  /// The data to render.
  final List<RecordingData> data;

  final PitchGraphStyle style;

  final int? dataLength;

  late final Paint linePaint = Paint()
    ..color = style.lineColor
    ..strokeWidth = style.lineWidth
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(covariant PitchGraphPainter oldDelegate) {
    return data != oldDelegate.data;
  }

  @override
  void paint(Canvas canvas, Size size) {
    /// The width that one data entry should fill.
    double dataWidth = size.width / (dataLength ?? data.length);

    Paint inTunePaint = Paint()..color = style.inTuneColor.withAlpha(0x1a);

    // Draw the "in tune"-rect
    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        size.height * (0.5 - Tuner.inTuneThreshold / 100.0),
        size.width,
        size.height * (0.5 + Tuner.inTuneThreshold / 100.0),
        const Radius.circular(5),
      ),
      inTunePaint,
    );

    final List<double?> frequencies = data
        .sublist(max(0, data.length - size.width ~/ dataWidth - 3))
        .map((e) => e.frequency)
        .toList()
        .reversed
        .toList();

    int i = 0;
    for (final pitches in splitFrequenciesByNote(frequencies)) {
      if (pitches == null) {
        i++;
        continue;
      }

      _drawChunk(pitches, canvas: canvas, size: size, startIndex: i);
      i += pitches.length;
    }
  }

  /// Split the [frequencies] into smaller chunks, where all frequencies in one chunk are closest to the same [Pitch].
  List<List<Pitch>?> splitFrequenciesByNote(List<double?> frequencies) {
    final List<List<Pitch>?> frequenciesByNote = [];
    List<Pitch> chunk = [];
    for (double? frequency in frequencies) {
      if (frequency == null) {
        if (chunk.isNotEmpty) {
          frequenciesByNote.add(chunk);
          chunk = [];
        }
        frequenciesByNote.add(null);
        continue;
      }

      final Pitch pitch = Tuner.instance.getClosestPitch(frequency);
      if (chunk.isEmpty || pitch.abbreviation == chunk.first.abbreviation) {
        chunk.add(pitch);
      } else {
        frequenciesByNote.add(chunk);
        chunk = [pitch];
      }
    }
    frequenciesByNote.add(chunk); // Add remaining
    return frequenciesByNote;
  }

  void _drawChunk(
    List<Pitch> chunk, {
    int startIndex = 0,
    required Canvas canvas,
    required Size size,
  }) {
    final List<Offset> offsets = [
      for (final (int i, Pitch pitch) in chunk.indexed)
        calculatePointOffset(
          startIndex + i,
          Tuner.instance.getPitchOffset(pitch),
          size,
        ),
    ];

    if (offsets.isNotEmpty) {
      canvas.drawPoints(
        style.continuous ? PointMode.polygon : PointMode.points,
        offsets,
        linePaint,
      );
    }

    if (offsets.length >= style.renderTextThreshold) {
      drawText(
        canvas,
        size,
        chunk[offsets.length - 1].frequency,
        offsets.last,
      );
    }
  }

  Offset calculatePointOffset(int index, double pitchOffset, Size size) {
    double dataWidth = size.width / (dataLength ?? data.length);
    return Offset(
      size.width - index * dataWidth,
      size.height / 2 - size.height * pitchOffset / 100,
    );
  }

  /// Draw text displaying the name of the [Pitch] closest to [frequency], above or below the line.
  void drawText(
    Canvas canvas,
    Size canvasSize,
    double frequency,
    Offset frequencyPosition,
  ) {
    final Pitch pitch = Tuner.instance.getClosestPitch(frequency);

    TextSpan span = TextSpan(
      text: pitch.abbreviation,
      style: style.textStyle ?? TextStyle(color: style.lineColor),
    );
    TextPainter textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: canvasSize.width);
    textPainter.paint(
      canvas,
      calculateTextOffset(
        canvasSize,
        textPainter,
        frequency - pitch.frequency,
        frequencyPosition,
      ),
    );
  }

  /// Calculate the offset for a text label.
  Offset calculateTextOffset(
    Size canvasSize,
    TextPainter textPainter,
    double pitchOffset,
    Offset frequencyPosition,
  ) {
    final double x = max(frequencyPosition.dx, 0);

    switch (style.textPlacement) {
      case TextPlacement.relative:
        return Offset(
          x,
          frequencyPosition.dy +
              (pitchOffset > 0
                  ? style.textOffset
                  : -(textPainter.height + style.textOffset)),
        );

      case TextPlacement.top:
        return Offset(x, 0);

      case TextPlacement.bottom:
        return Offset(
          x,
          canvasSize.height - textPainter.height,
        );
    }
  }
}
