import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

/// Slider for adjusting [Metronome]'s bpm.
class BpmSlider extends StatelessWidget {
  const BpmSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Metronome.instance.bpmNotifier,
      builder: (context, child) {
        return Slider(
          min: Metronome.minBpm.toDouble(),
          max: Metronome.maxBpm.toDouble(),
          value: Metronome.instance.bpm.toDouble(),
          onChanged: (value) {
            Metronome.instance.bpm = value.toInt();
          },
          onChangeEnd: (value) {
            Metronome.instance.reset();
          },
        );
      },
    );
  }
}
