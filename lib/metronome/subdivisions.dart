import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/widgets/custom_icons.dart';

class Subdivisions extends StatelessWidget {
  const Subdivisions({super.key, this.iconSize = 32.0});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final Metronome metronome = Metronome.instance;

    return ListenableBuilder(
      listenable: metronome.subdivisionsNotifier,
      builder: (context, child) {
        return SegmentedButton<int>(
          showSelectedIcon: false,
          selected: {metronome.subdivisions},
          onSelectionChanged: (value) {
            metronome.subdivisions = value.single;
          },
          style: SegmentedButton.styleFrom(
            iconColor: Theme.of(context).colorScheme.onSurface,
          ),
          segments: [
            ButtonSegment(
              value: 1,
              icon: Icon(CustomIcons.crotchet, size: iconSize),
            ),
            ButtonSegment(
              value: 2,
              icon: Icon(CustomIcons.quavers_two, size: iconSize),
            ),
            ButtonSegment(
              value: 3,
              icon: Icon(CustomIcons.quavers_three, size: iconSize),
            ),
            ButtonSegment(
              value: 4,
              icon: Icon(CustomIcons.semiquavers_four, size: iconSize),
            ),
          ],
        );
      },
    );
  }
}
