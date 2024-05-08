import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/widgets.dart';

class BpmButtons extends StatelessWidget {
  /// Buttons for adjusting [Metronome]'s bpm and a label showing the current bpm,
  /// arranged horizontally.
  const BpmButtons({super.key, this.iconSize = 50});

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
          child: IconButton(
            onPressed: () {
              Metronome.instance.bpm--;
            },
            color: Theme.of(context).colorScheme.primary,
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              size: iconSize,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80),
          child: buildBpmText(context),
        ),
        ContinuousButton(
          onContinuousPress: () {
            Metronome.instance.bpm++;
          },
          onContinuousPressEnd: () {
            Metronome.instance.reset();
          },
          child: IconButton(
            onPressed: () {
              Metronome.instance.bpm++;
            },
            color: Theme.of(context).colorScheme.primary,
            icon: Icon(
              Icons.arrow_drop_up_rounded,
              size: iconSize,
            ),
          ),
        )
      ],
    );
  }

  Widget buildBpmText(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Metronome.instance.bpmNotifier,
      builder: (c, int bpm, Widget? child) {
        return Text(
          "$bpm",
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
