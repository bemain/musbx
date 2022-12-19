import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/drone/drone.dart';
import 'package:musbx/drone/drone_player.dart';
import 'package:musbx/note/note.dart';

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
    final double angle = 2 * pi * index / 12 - pi / 2;
    DronePlayer player = drone.players[index];
    return ValueListenableBuilder(
        valueListenable: drone.players[index].isPlayingNotifier,
        builder: (context, active, _) {
          bool isReference =
              (Note.fromFrequency(player.frequency).name == drone.root.name);
          Color buttonColor = isReference
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer;
          Color textColor = isReference
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onPrimaryContainer;

          return Transform.translate(
            offset: Offset(cos(angle), sin(angle)) * widget.radius,
            child: FloatingActionButton(
              elevation: active ? 0 : 6,
              backgroundColor:
                  active ? buttonColor.withOpacity(0.5) : buttonColor,
              onPressed: () {
                if (active) {
                  player.pause();
                } else {
                  player.play();
                }
              },
              child: Text(
                Note.fromFrequency(player.frequency).name,
                style: TextStyle(
                  color: textColor,
                ),
              ),
            ),
          );
        });
  }
}
