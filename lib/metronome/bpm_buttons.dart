import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/widgets.dart';

class BpmButtons extends StatelessWidget {
  /// Buttons for adjusting bpm and a label showing the current bpm,
  /// arranged horizontally.
  const BpmButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ContinuousButton(
          onPressed: () {
            Metronome.bpm++;
          },
          child: const Icon(
            Icons.arrow_drop_up,
            size: 35,
          ),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: _buildBpmText()),
        ContinuousButton(
          onPressed: () {
            Metronome.bpm--;
          },
          child: const Icon(
            Icons.arrow_drop_down,
            size: 35,
          ),
        )
      ],
    );
  }

  Widget _buildBpmText() {
    return ValueListenableBuilder(
      valueListenable: Metronome.bpmNotifier,
      builder: (c, int bpm, Widget? child) {
        return Text(
          "$bpm",
          style: const TextStyle(fontSize: 20),
        );
      },
    );
  }
}
