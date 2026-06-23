import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/metronome/metronome.dart';

class BpmButtons extends StatelessWidget {
  /// Buttons for adjusting [Metronome]'s bpm and a label showing the current bpm,
  /// arranged horizontally.
  const BpmButtons({super.key, this.iconSize = 25});

  /// Size of the buttons for adjusting bpm.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ContinuousButton(
          onContinuousPress: () {
            Metronome.instance.bpm--;
          },
          onContinuousPressEnd: () {
            Metronome.instance.reset();
          },
          child: IconButtonM3E(
            onPressed: () {
              Metronome.instance.bpm--;
            },
            icon: Icon(Symbols.remove, size: iconSize),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 90),
          child: buildBpmText(context),
        ),
        ContinuousButton(
          onContinuousPress: () {
            Metronome.instance.bpm++;
          },
          onContinuousPressEnd: () {
            Metronome.instance.reset();
          },
          child: IconButtonM3E(
            onPressed: () {
              Metronome.instance.bpm++;
            },
            icon: Icon(Symbols.add, size: iconSize),
          ),
        ),
      ],
    );
  }

  Widget buildBpmText(BuildContext context) {
    return SizedBox(
      width: 90,
      child: ListenableBuilder(
        listenable: Metronome.instance.bpmNotifier,
        builder: (context, child) {
          return NumberField<int>(
            value: Metronome.instance.bpm,
            style: Theme.of(context).textTheme.displayMedium,
            min: Metronome.minBpm,
            max: Metronome.maxBpm,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (value) {
              Metronome.instance.bpm = value;
              Metronome.instance.reset();
            },
          );
        },
      ),
    );
  }
}
