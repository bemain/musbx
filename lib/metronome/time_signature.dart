import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

/// The most common `higher` values for each `lower` value.
const Map<int, List<int>> commonTimeSignatures = {
  2: [1, 2, 3],
  4: [1, 2, 3, 4, 5, 6],
  8: [3, 5, 6, 7, 9, 12],
};
final List<int> commonLowers = commonTimeSignatures.keys.toList();

class TimeSignature extends StatelessWidget {
  /// Displays and features buttons for changing the [Metronome]'s key signature.
  const TimeSignature({super.key});

  @override
  Widget build(BuildContext context) {
    final Metronome metronome = Metronome.instance;

    return ValueListenableBuilder(
      valueListenable: metronome.lowerNotifier,
      builder: (context, lower, child) {
        final int lowerIndex = commonLowers.indexOf(lower);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: metronome.higherNotifier,
              builder: (context, higher, child) {
                final List<int> commonHighers = commonTimeSignatures[lower]!;
                int higherIndex = commonHighers.indexOf(higher);

                return _buildButtonsAndLabel(
                  context,
                  label: "$higher",
                  onDecreasePressed: higherIndex <= 0
                      ? null
                      : () {
                          metronome.higher = commonHighers[higherIndex - 1];
                        },
                  onIncreasePressed: higherIndex >= commonHighers.length - 1
                      ? null
                      : () {
                          metronome.higher = commonHighers[higherIndex + 1];
                        },
                );
              },
            ),
            const SizedBox(width: 50, child: Divider(thickness: 2.0)),
            _buildButtonsAndLabel(
              context,
              label: "$lower",
              onDecreasePressed: lowerIndex <= 0
                  ? null
                  : () {
                      metronome.lower = commonLowers[lowerIndex - 1];

                      final List<int> commonHighers =
                          commonTimeSignatures[metronome.lower]!;
                      if (!commonHighers.contains(metronome.higher)) {
                        metronome.higher = commonHighers.first;
                      }
                    },
              onIncreasePressed: lowerIndex >= commonLowers.length - 1
                  ? null
                  : () {
                      metronome.lower = commonLowers[lowerIndex + 1];

                      final List<int> commonHighers =
                          commonTimeSignatures[metronome.lower]!;
                      if (!commonHighers.contains(metronome.higher)) {
                        metronome.higher = commonHighers.first;
                      }
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtonsAndLabel(
    BuildContext context, {
    required String label,
    void Function()? onDecreasePressed,
    void Function()? onIncreasePressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onDecreasePressed,
          color: Theme.of(context).colorScheme.primary,
          iconSize: 50,
          icon: const Icon(Icons.arrow_left_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            label,
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        IconButton(
          onPressed: onIncreasePressed,
          color: Theme.of(context).colorScheme.primary,
          iconSize: 50,
          icon: const Icon(Icons.arrow_right_rounded),
        ),
      ],
    );
  }
}
