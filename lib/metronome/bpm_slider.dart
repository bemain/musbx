import 'package:flutter/material.dart';
import 'package:musbx/data/repositories/metronome_repository.dart';
import 'package:provider/provider.dart';

/// Slider for adjusting [Metronome]'s bpm.
class BpmSlider extends StatelessWidget {
  const BpmSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final MetronomeRepository metronome = context.read();

    return Slider(
      min: MetronomeRepository.minBpm.toDouble(),
      max: MetronomeRepository.maxBpm.toDouble(),
      value: metronome.bpm.toDouble(),
      onChanged: (value) {
        metronome.bpm = value.toInt();
      },
    );
  }
}
