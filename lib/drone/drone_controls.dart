import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/drone/drone.dart';
import 'package:musbx/tuner/note.dart';

class DroneControls extends StatefulWidget {
  const DroneControls({super.key, this.radius = 150});

  final double radius;

  @override
  State<StatefulWidget> createState() => DroneControlsState();
}

class DroneControlsState extends State<DroneControls> {
  final Drone drone = Drone.instance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) => SizedBox(
        height: constraints.maxWidth,
        child: Stack(alignment: Alignment.center, children: [
          buildResetButton(),
          ...List.generate(12, (index) => buildDroneButton(index)),
        ]),
      ),
    );
  }

  Widget buildResetButton() {
    return ValueListenableBuilder(
      valueListenable: drone.isActiveNotifier,
      builder: (context, isActive, _) => TextButton(
        onPressed: !isActive
            ? null
            : () {
                drone.pauseAll();
              },
        child: const Icon(
          Icons.pause_circle_rounded,
          size: 75,
        ),
      ),
    );
  }

  Widget buildDroneButton(int index) {
    final double angle = 2 * pi * index / 12 - pi;
    DronePlayer player = drone.players[index];
    return ValueListenableBuilder(
        valueListenable: drone.players[index].isPlayingNotifier,
        builder: (context, active, _) {
          return Transform.translate(
            offset: Offset(cos(angle), sin(angle)) * widget.radius,
            child: FloatingActionButton(
              elevation: active ? 0 : 6,
              backgroundColor: active
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.5)
                  : null,
              onPressed: () {
                if (active) {
                  player.pause();
                } else {
                  player.play();
                }
              },
              child: Text(Note.fromFrequency(player.frequency).name),
            ),
          );
        });
  }
}
