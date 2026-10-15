import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/metronome/metronome_repository.dart';
import 'package:provider/provider.dart';

/// Widget for displaying the number of beat and the [Metronome]'s current count.
class CountDisplay extends StatefulWidget {
  const CountDisplay({super.key});

  @override
  State<StatefulWidget> createState() => CountDisplayState();
}

class CountDisplayState extends State<CountDisplay> {
  MetronomeRepository get metronome => context.read();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(metronome.higher, (index) {
        return Icon(
          (metronome.beat == index)
              ? Symbols.radio_button_checked
              : Symbols.circle, // Highlight current beat
          color: Theme.of(context).colorScheme.primary,
        );
      }),
    );
  }
}
