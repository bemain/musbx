import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/metronome/metronome.dart';

class Higher extends StatelessWidget {
  /// Displays and features buttons for changing the [Metronome]'s key signature.
  const Higher({super.key, this.size = 64.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final Metronome metronome = Metronome.instance;

    return ListenableBuilder(
      listenable: metronome.higherNotifier,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButtonM3E(
              onPressed: metronome.higher <= 1
                  ? null
                  : () {
                      metronome.higher--;
                    },
              size: IconButtonM3ESize.md,
              icon: const Icon(Symbols.arrow_left_rounded, size: 48),
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
            IconButtonM3E(
              onPressed: metronome.higher >= 7
                  ? null
                  : () {
                      metronome.higher++;
                    },
              size: IconButtonM3ESize.md,
              icon: const Icon(Symbols.arrow_right_rounded, size: 48),
            ),
          ],
        );
      },
    );
  }
}
