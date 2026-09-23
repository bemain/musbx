import 'dart:math' show max;
import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/tuner/tuner_reading.dart';
import 'package:musbx/tuner/waveform_graph.dart';
import 'package:provider/provider.dart';

/// How a [PitchGraph] is drawn.
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

/// Graph showing how the tuning of [data] has changed over time.
class PitchGraph extends StatelessWidget {
  const PitchGraph({super.key, required this.data});

  /// The frequencies to display.
  final List<TunerReading> data;

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
              dataLength: TunerRepository.bufferLength,
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
              chunks: TunerRepository.bufferLength * 2,
              audioScale: 48.0,
            ),
            size: const Size(double.infinity, 150),
          ),
        ],
      ),
    );
  }

  /// Get the pitch closest to the given [frequency].
  Pitch? getClosestPitch(BuildContext context, double? frequency) {
    if (frequency == null) return null;
    final settings = context.read<SettingsRepository>().tuner;
    return Pitch.closest(
      frequency,
      tuning: settings.tuning,
      temperament: settings.temperament,
      preferredAccidental: settings.preferredAccidental,
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

/// Paints a line showing how the tuning of [data] has changed over time.
///
/// Displays text showing the names of the closest [Pitch]es.
/// Highlights the section where the tone is in tune in green.
class PitchGraphPainter extends CustomPainter {
  PitchGraphPainter({
    required this.data,
    required this.style,
    this.dataLength,
  });

  /// The data to render.
  final List<TunerReading> data;

  /// How to draw the graph.
  final PitchGraphStyle style;

  /// How many entries the graph is scaled to fit. Defaults to however many there
  /// currently are, which makes the line stretch as data comes in.
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
        size.height * (0.5 - TunerRepository.inTuneThreshold / 100.0),
        size.width,
        size.height * (0.5 + TunerRepository.inTuneThreshold / 100.0),
        const Radius.circular(5),
      ),
      inTunePaint,
    );

    final List<TunerReading> readings = data
        .sublist(max(0, data.length - size.width ~/ dataWidth - 3))
        .toList()
        .reversed
        .toList();

    int i = 0;
    for (final byNote in splitFrequenciesByNote(readings)) {
      if (byNote == null) {
        i++;
        continue;
      }

      _drawChunk(byNote, canvas: canvas, size: size, startIndex: i);
      i += byNote.length;
    }
  }

  /// Split the [pitches] into smaller chunks, where all frequencies in one chunk are closest to the same [Pitch].
  List<List<TunerReading>?> splitFrequenciesByNote(
    List<TunerReading> pitches,
  ) {
    final List<List<TunerReading>?> frequenciesByNote = [];
    List<TunerReading> chunk = [];
    for (TunerReading reading in pitches) {
      final pitch = reading.pitch;
      if (pitch == null) {
        if (chunk.isNotEmpty) {
          frequenciesByNote.add(chunk);
          chunk = [];
        }
        frequenciesByNote.add(null);
        continue;
      }

      if (chunk.isEmpty ||
          pitch.abbreviation == chunk.first.pitch?.abbreviation) {
        chunk.add(reading);
      } else {
        frequenciesByNote.add(chunk);
        chunk = [reading];
      }
    }
    frequenciesByNote.add(chunk); // Add remaining
    return frequenciesByNote;
  }

  void _drawChunk(
    List<TunerReading> chunk, {
    int startIndex = 0,
    required Canvas canvas,
    required Size size,
  }) {
    final List<Offset> offsets = [
      for (final (int i, TunerReading reading) in chunk.indexed)
        calculatePointOffset(
          startIndex + i,
          reading.offset ?? 0.0,
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
        chunk[offsets.length - 1],
        offsets.last,
      );
    }
  }

  /// Where on the canvas the reading at [index] sits, given how many cents off it
  /// is.
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
    TunerReading reading,
    Offset position,
  ) {
    if (reading.pitch == null) return;

    TextSpan span = TextSpan(
      text: reading.pitch!.abbreviation,
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
        reading.offset!,
        position,
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
