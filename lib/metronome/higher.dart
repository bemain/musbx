import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

/// The most common `higher` values
final List<int> commonHighers = [1, 2, 3, 4, 5, 6, 7];

class Higher extends StatelessWidget {
  /// Displays and features buttons for changing the [Metronome]'s key signature.
  const Higher({super.key, this.size = 64.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final Metronome metronome = Metronome.instance;

    return ValueListenableBuilder(
      valueListenable: metronome.higherNotifier,
      builder: (context, higher, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: higher <= 1
                  ? null
                  : () {
                      metronome.higher--;
                    },
              color: Theme.of(context).colorScheme.primary,
              iconSize: 50,
              icon: const Icon(Icons.arrow_left_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "$higher",
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: size),
              ),
            ),
            IconButton(
              onPressed: higher >= 7
                  ? null
                  : () {
                      metronome.higher++;
                    },
              color: Theme.of(context).colorScheme.primary,
              iconSize: 50,
              icon: const Icon(Icons.arrow_right_rounded),
            ),
          ],
        );
      },
    );
  }
}
