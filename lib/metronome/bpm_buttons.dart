import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/widgets.dart';

class BpmButtons extends StatelessWidget {
  /// Buttons for adjusting [Metronome]'s bpm and a label showing the current bpm,
  /// arranged horizontally.
  const BpmButtons({super.key, this.iconSize = 30, this.fontSize = 25});

  /// Font size of the label showing the current bpm.
  final double fontSize;

  /// Size of the buttons for adjusting bpm.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ContinuousButton(
          onPressed: () {
            Metronome.bpm--;
          },
          child: Icon(
            Icons.arrow_drop_down_rounded,
            size: iconSize,
          ),
        ),
        SizedBox(
          width: fontSize * 2,
          child: buildBpmText(),
        ),
        ContinuousButton(
          onPressed: () {
            Metronome.bpm++;
          },
          child: Icon(
            Icons.arrow_drop_up_rounded,
            size: iconSize,
          ),
        )
      ],
    );
  }

  Widget buildBpmText() {
    return ValueListenableBuilder(
      valueListenable: Metronome.bpmNotifier,
      builder: (c, int bpm, Widget? child) {
        return Text(
          "$bpm",
          style: TextStyle(fontSize: fontSize),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
