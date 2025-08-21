import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/drone/drone.dart';

class DroneOctave extends StatelessWidget {
  const DroneOctave({super.key, this.size = 64.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final Drone drone = Drone.instance;

    return ListenableBuilder(
      listenable: drone.rootNotifier,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Octave",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: drone.root.octave <= Drone.minOctave
                      ? null
                      : () {
                          drone.root = drone.root.transposed(-12);
                        },
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: 50,
                  icon: const Icon(Symbols.arrow_left_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "${drone.root.octave}",
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(fontSize: size),
                  ),
                ),
                IconButton(
                  onPressed: drone.root.octave >= Drone.maxOctave
                      ? null
                      : () {
                          drone.root = drone.root.transposed(12);
                        },
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: 50,
                  icon: const Icon(Symbols.arrow_right_rounded),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
