import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

class BpmSlider extends StatelessWidget {
  /// Slider for adjusting [Metronome]'s bpm.
  const BpmSlider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Metronome.instance.bpmNotifier,
      builder: (context, Widget? child) {
        return Slider(
          min: Metronome.minBpm.toDouble(),
          max: Metronome.maxBpm.toDouble(),
          value: Metronome.instance.bpm.toDouble(),
          onChanged: (double value) {
            Metronome.instance.bpm = value.toInt();
          },
          onChangeEnd: (double value) {
            Metronome.instance.reset();
          },
        );
      },
    );
  }
}
