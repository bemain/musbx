import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

class BpmSlider extends StatelessWidget {
  /// Simple Slider for adjusting [Metronome]'s bpm.
  const BpmSlider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Metronome.bpmNotifier,
      builder: (c, int bpm, Widget? child) {
        return Slider(
          min: Metronome.minBpm.toDouble(),
          max: Metronome.maxBpm.toDouble(),
          value: Metronome.bpm.toDouble(),
          onChanged: (double value) {
            Metronome.bpm = value.toInt();
          },
        );
      },
    );
  }
}
