import 'dart:math';

import 'package:flutter/material.dart' hide Key;
import 'package:musbx/drone/drone.dart';
import 'package:musbx/model/key.dart';
import 'package:musbx/model/pitch.dart';

enum DroneButtonType {
  /// This pitch is the current root
  root,

  /// This pitch belongs to the root's major key.
  diatonic,

  /// This pitch is not in the root's major key.
  chromatic,
}

class DroneControls extends StatefulWidget {
  /// A wheel with buttons that create drone tones in the chromatic scale starting from the [Drone]'s root.
  const DroneControls({super.key, this.radius = 150});

  /// The radius of the wheel.
  final double radius;

  @override
  State<StatefulWidget> createState() => DroneControlsState();
}

class DroneControlsState extends State<DroneControls> {
  final Drone drone = Drone.instance;

  /// The current rotation angle
  double angle = 0;

  @override
  Widget build(BuildContext context) {
    final List<Pitch> pitches = List.generate(12, drone.root.transposed);

    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) => SizedBox.square(
        dimension: constraints.biggest.shortestSide,
        child: GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            setState(() {
              angle = details.localPosition.direction;
            });
          },
          onPanEnd: (details) {
            final int shift = (12 * angle / (2 * pi)).round();
            drone.rootNotifier.value = drone.root.transposed(shift);
            angle %= shift * 12 / (2 * pi);
          },
          child: ListenableBuilder(
            listenable: drone.pitchesNotifier,
            builder: (context, child) {
              return Stack(alignment: Alignment.center, children: [
                buildResetButton(),
                for (final Pitch pitch in pitches) buildDroneButton(pitch),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget buildResetButton() {
    return ValueListenableBuilder(
      valueListenable: drone.isPlayingNotifier,
      builder: (context, isPlaying, _) => IconButton(
        onPressed: drone.pitches.isEmpty
            ? null
            : isPlaying
                ? drone.pause
                : drone.play,
        icon: Icon(
          isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 75,
        ),
      ),
    );
  }

  Widget buildDroneButton(Pitch pitch) {
    final int index = pitch.semitonesTo(drone.root).abs();
    final double buttonAngle = index * 2 * pi / 12 + pi / 2 + angle;

    final DroneButtonType type = pitch.pitchClass == drone.root.pitchClass
        ? DroneButtonType.root
        : Key.major(drone.root.pitchClass).notes.contains(pitch.pitchClass)
            ? DroneButtonType.diatonic
            : DroneButtonType.chromatic;

    Color backgroundColor = switch (type) {
      DroneButtonType.root => Theme.of(context).colorScheme.primary,
      DroneButtonType.diatonic =>
        Theme.of(context).colorScheme.surfaceContainer,
      DroneButtonType.chromatic =>
        Theme.of(context).colorScheme.primaryContainer
    };
    Color textColor = switch (type) {
      DroneButtonType.root => Theme.of(context).colorScheme.onPrimary,
      DroneButtonType.diatonic => Theme.of(context).colorScheme.onSurface,
      DroneButtonType.chromatic =>
        Theme.of(context).colorScheme.onPrimaryContainer
    };

    final bool isPlaying = drone.pitches.contains(pitch);

    return Transform.translate(
      offset: Offset(cos(buttonAngle), sin(buttonAngle)) * widget.radius,
      child: FloatingActionButton(
        elevation: isPlaying ? 0 : 6,
        backgroundColor:
            isPlaying ? backgroundColor.withOpacity(0.5) : backgroundColor,
        onPressed: () {
          if (isPlaying) {
            drone.pitchesNotifier.remove(pitch);
          } else {
            drone.pitchesNotifier.add(pitch);
            drone.play();
          }
        },
        child: Text(
          pitch.pitchClass.abbreviation,
          style: TextStyle(
            color: textColor,
          ),
        ),
      ),
    );
  }
}
