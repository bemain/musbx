import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:musbx/tuner/note.dart';
import 'package:musbx/tuner/tuner.dart';

class TuningGraph extends StatelessWidget {
  const TuningGraph({super.key, required this.noteHistory});

  final List<Note> noteHistory;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TuningGraphPainter(
        noteHistory: noteHistory,
        lineColor: Colors.white,
      ),
      size: const Size(0, 150),
    );
  }
}

class TuningGraphPainter extends CustomPainter {
  /// Paints a line showing the tuning of the notes in [noteHistory].
  ///
  /// Displays text showing the name of the tone.
  /// Highlights the section where the tone is in tune in green.
  TuningGraphPainter({
    this.continuous = false,
    required this.noteHistory,
    required this.lineColor,
    this.lineWidth = 4.0,
    this.renderTextThreshold = 15,
    Color? textColor,
    this.textOffset = 15.0,
  }) : textColor = textColor ?? lineColor;

  /// Whether to render the notes as a continuous line.
  /// Otherwise renders them as points.
  final bool continuous;

  /// The notes to render.
  final List<Note> noteHistory;

  /// The color used when rendering the notes.
  final Color lineColor;

  /// The width used when rendering the notes.
  final double lineWidth;

  /// The color of the text displaying the note name.
  final Color textColor;

  /// How much to offset the text in the y-direction.
  ///
  /// The text is placed below the line if pitchOffset < 0 and above otherwise.
  final double textOffset;

  /// The minimum entries of the same note in a row required to render text.
  final int renderTextThreshold;

  @override
  bool shouldRepaint(covariant TuningGraphPainter oldDelegate) {
    return noteHistory != oldDelegate.noteHistory;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint inTunePaint = Paint()..color = Colors.green.withOpacity(0.1);

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

    final List<Note> notes =
        noteHistory.sublist(max(0, noteHistory.length - size.width.toInt()));
    drawNotes(canvas, size, notes);
  }

  /// Split the notes into smaller chunks, by name.
  List<List<Note>> splitNotesByName(List<Note> notes) {
    final List<List<Note>> notesByName = [];
    List<Note> chunk = [];
    for (Note note in notes) {
      if (chunk.isEmpty || note.name == chunk.first.name) {
        chunk.add(note);
      } else {
        notesByName.add(chunk);
        chunk = [note];
      }
    }
    notesByName.add(chunk);
    return notesByName;
  }

  /// Draw the note line and text.
  void drawNotes(Canvas canvas, Size size, List<Note> notes) {
    Paint notePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    int index = 0;
    for (List<Note> notes in splitNotesByName(notes).reversed) {
      Note? lastNote;
      List<Offset> offsets = [];
      for (Note note in notes.reversed) {
        if (index <= size.width.toInt()) {
          offsets.add(calculateOffset(index, note, size));
          index++;

          lastNote = note;
        }
      }

      if (offsets.isEmpty || lastNote == null) return;

      canvas.drawPoints(
        continuous ? PointMode.polygon : PointMode.points,
        offsets,
        notePaint,
      );
      index += 5;

      if (offsets.length >= renderTextThreshold) {
        drawText(canvas, size, offsets.last, lastNote);
      }
    }
  }

  /// Draw text displaying the [lastNote]'s name, above or below the line.
  void drawText(Canvas canvas, Size size, Offset position, Note lastNote) {
    TextSpan span = TextSpan(
      text: lastNote.name,
      style: TextStyle(color: textColor),
    );
    TextPainter textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      position.translate(
        0,
        (lastNote.pitchOffset > 0)
            ? textOffset
            : -(textPainter.height + textOffset),
      ),
    );
  }

  Offset calculateOffset(int index, Note note, Size canvasSize) {
    return Offset(
      canvasSize.width - index,
      canvasSize.height / 2 - canvasSize.height * note.pitchOffset / 100,
    );
  }
}
