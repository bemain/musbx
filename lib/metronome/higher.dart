import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/metronome_repository.dart';
import 'package:provider/provider.dart';

/// Displays and features buttons for changing the [Metronome]'s key signature.
class Higher extends StatelessWidget {
  const Higher({super.key, this.size = 64.0});

  /// The font size of the beat count.
  final double size;

  @override
  Widget build(BuildContext context) {
    final MetronomeRepository metronome = context.read();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: metronome.higher <= 1
              ? null
              : () {
                  metronome.higher--;
                },
          color: Theme.of(context).colorScheme.primary,
          iconSize: 50,
          icon: const Icon(Symbols.arrow_left_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "${metronome.higher}",
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: size),
          ),
        ),
        IconButton(
          onPressed: metronome.higher >= 7
              ? null
              : () {
                  metronome.higher++;
                },
          color: Theme.of(context).colorScheme.primary,
          iconSize: 50,
          icon: const Icon(Symbols.arrow_right_rounded),
        ),
      ],
    );
  }
}
