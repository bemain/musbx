import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/metronome/metronome_repository.dart';
import 'package:provider/provider.dart';

/// Buttons for adjusting [Metronome]'s bpm and a label showing the current bpm,
/// arranged horizontally.
class BpmButtons extends StatelessWidget {
  const BpmButtons({super.key, this.iconSize = 25});

  /// Size of the buttons for adjusting bpm.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final MetronomeRepository metronome = context.read();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ContinuousButton(
          onContinuousPress: () {
            metronome.bpm--;
          },
          child: IconButton(
            onPressed: () {
              metronome.bpm--;
            },
            iconSize: iconSize,
            icon: const Icon(Symbols.remove),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 90),
          child: buildBpmText(context),
        ),
        ContinuousButton(
          onContinuousPress: () {
            metronome.bpm++;
          },
          child: IconButton(
            onPressed: () {
              metronome.bpm++;
            },
            iconSize: iconSize,
            icon: const Icon(Symbols.add),
          ),
        ),
      ],
    );
  }

  Widget buildBpmText(BuildContext context) {
    final MetronomeRepository metronome = context.read();

    return SizedBox(
      width: 90,
      child: NumberField<int>(
        value: metronome.bpm,
        style: Theme.of(context).textTheme.displayMedium,
        min: MetronomeRepository.minBpm,
        max: MetronomeRepository.maxBpm,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (value) {
          metronome.bpm = value;
        },
      ),
    );
  }
}
