import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:musbx/tuner/note.dart';
import 'package:musbx/tuner/tuner.dart';

class TuningGraph extends StatelessWidget {
  const TuningGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Tuner.instance.currentNoteNotifier,
      builder: (context, currentNote, child) => CustomPaint(
        painter: TuningGraphPainter(
          backgroundColor: Theme.of(context).colorScheme.background,
          foregroundColor: Colors.white,
          noteHistory: Tuner.instance.noteHistory,
        ),
        size: Size(100, 100),
      ),
    );
  }
}

class TuningGraphPainter extends CustomPainter {
  TuningGraphPainter({
    required this.noteHistory,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;

  final List<Note> noteHistory;

  @override
  bool shouldRepaint(covariant TuningGraphPainter oldDelegate) {
    return noteHistory != oldDelegate.noteHistory;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint inTunePaint = Paint()..color = Colors.green.withOpacity(0.1);

    Paint foregroundPaint = Paint()
      ..color = foregroundColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          size.height / 2 - Tuner.inTuneThreshold,
          size.width,
          size.height / 2 + Tuner.inTuneThreshold,
          const Radius.circular(5),
        ),
        inTunePaint);

    final List<Note> notes =
        noteHistory.sublist(max(0, noteHistory.length - size.width.toInt()));

    canvas.drawPoints(
      PointMode.points,
      notes
          .asMap()
          .entries
          .map((e) => calculateOffset(e.key, e.value, size))
          .toList(),
      foregroundPaint,
    );
  }

  Offset calculateOffset(int index, Note note, Size canvasSize) {
    return Offset(
      index.toDouble(),
      canvasSize.height / 2 - canvasSize.height * note.pitchOffset / 100,
    );
  }
}
