import 'dart:math';
import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/tuner/tuner.dart';

class TuningGraph extends StatelessWidget {
  /// Graph showing how the tuning of [frequencyHistory] has changed over time.
  const TuningGraph({super.key, required this.frequencyHistory});

  /// The frequencies to display.
  final List<double> frequencyHistory;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TuningGraphPainter(
        frequencyHistory: frequencyHistory,
        lineColor: Theme.of(context).colorScheme.primary,
        textStyle:
            GoogleFonts.andikaTextTheme(Theme.of(context).textTheme).bodyMedium,
        inTuneColor:
            Colors.green.harmonizeWith(Theme.of(context).colorScheme.primary),
        textPlacement: TextPlacement.top,
        newNotePadding: 8,
      ),
      size: const Size(double.infinity, 150),
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

class TuningGraphPainter extends CustomPainter {
  /// Paints a line showing the tuning of the frequencies in [frequencyHistory].
  ///
  /// Displays text showing the names of the closest [Pitch]s.
  /// Highlights the section where the tone is in tune in green.
  TuningGraphPainter({
    this.continuous = false,
    this.inTuneColor = Colors.green,
    this.newNotePadding = 5,
    required this.frequencyHistory,
    required this.lineColor,
    this.lineWidth = 4.0,
    this.renderTextThreshold = 15,
    this.textStyle,
    this.textPlacement = TextPlacement.relative,
    this.textOffset = 15.0,
  });

  /// Whether to render the frequencies as a continuous line.
  /// Otherwise renders them as points.
  final bool continuous;

  /// The color used for the segment indicating where the frequency is in tune.
  final Color inTuneColor;

  /// How many empty pixels to put between notes of different names.
  final int newNotePadding;

  /// The frequencies to render.
  final List<double> frequencyHistory;

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

  @override
  bool shouldRepaint(covariant TuningGraphPainter oldDelegate) {
    return frequencyHistory != oldDelegate.frequencyHistory;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint inTunePaint = Paint()..color = inTuneColor.withOpacity(0.1);

    // Draw the "in tune"-rect
    canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          size.height * (0.5 - Tuner.inTuneThreshold / 100.0),
          size.width,
          size.height * (0.5 + Tuner.inTuneThreshold / 100.0),
          const Radius.circular(5),
        ),
        inTunePaint);

    final List<double> frequencies = frequencyHistory
        .sublist(max(0, frequencyHistory.length - size.width.toInt()));
    drawFrequencies(canvas, size, frequencies);
  }

  /// Split the [frequencies] into smaller chunks, where all frequencies in one chunk are closest to the same [Pitch].
  List<List<double>> splitFrequenciesByNote(List<double> frequencies) {
    final List<List<double>> frequenciesByNote = [];
    List<double> chunk = [];
    for (double frequency in frequencies) {
      final Pitch pitch = Tuner.instance.getClosestPitch(frequency);
      if (chunk.isEmpty ||
          pitch.abbreviation ==
              Tuner.instance.getClosestPitch(chunk.first).abbreviation) {
        chunk.add(frequency);
      } else {
        frequenciesByNote.add(chunk);
        chunk = [frequency];
      }
    }
    frequenciesByNote.add(chunk);
    return frequenciesByNote;
  }

  /// Draw the frequency line and text labels.
  void drawFrequencies(Canvas canvas, Size size, List<double> frequencies) {
    Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    int index = 0;
    for (List<double> frequencyChunk
        in splitFrequenciesByNote(frequencies).reversed) {
      double? lastFrequency;
      List<Offset> offsets = [];
      for (double frequency in frequencyChunk.reversed) {
        if (index <= size.width.toInt()) {
          offsets.add(calculatePointOffset(
            index,
            Tuner.instance.getPitchOffset(frequency),
            size,
          ));
          index++;

          lastFrequency = frequency;
        }
      }

      if (offsets.isEmpty || lastFrequency == null) return;

      canvas.drawPoints(
        continuous ? PointMode.polygon : PointMode.points,
        offsets,
        paint,
      );
      index += newNotePadding;

      if (offsets.length >= renderTextThreshold) {
        drawText(canvas, size, lastFrequency, offsets.last);
      }
    }
  }

  Offset calculatePointOffset(int index, double pitchOffset, Size canvasSize) {
    return Offset(
      canvasSize.width - index,
      canvasSize.height / 2 - canvasSize.height * pitchOffset / 100,
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
      style: textStyle ?? TextStyle(color: lineColor),
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
    switch (textPlacement) {
      case TextPlacement.relative:
        return frequencyPosition.translate(
          0,
          (pitchOffset > 0) ? textOffset : -(textPainter.height + textOffset),
        );

      case TextPlacement.top:
        return Offset(frequencyPosition.dx, 0);

      case TextPlacement.bottom:
        return Offset(
            frequencyPosition.dx, canvasSize.height - textPainter.height);
    }
  }
}
