import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart' hide Key;
import 'package:musbx/drone/drone.dart';
import 'package:musbx/model/key.dart';
import 'package:musbx/model/pitch.dart';

enum DroneButtonType {
  /// This pitch is the current root.
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
          onPanStart: (details) {
            drone.pitchesNotifier.clear();
          },
          onPanUpdate: (DragUpdateDetails details) {
            Offset center = Offset(constraints.biggest.shortestSide / 2,
                constraints.biggest.shortestSide / 2);
            Offset a = details.localPosition - center;
            Offset b = (details.localPosition - details.delta) - center;

            final double deltaAngle = atan2(
              a.dx * b.dy - a.dy * b.dx,
              a.dx * b.dx + a.dy * b.dy,
            );

            setState(() {
              angle -= deltaAngle;

              final int semitones = -(12 * angle / (2 * pi)).round();
              if (semitones != 0) {
                drone.rootNotifier.value = drone.root.transposed(
                  semitones,
                  temperament: drone.temperament,
                );
                angle += semitones * 2 * pi / 12;
              }
            });
          },
          onPanEnd: (details) async {
            // Easy way to center the root at the top
            for (int i = 0; i < 10; i++) {
              setState(() {
                angle *= 0.5;
              });
              await Future.delayed(const Duration(milliseconds: 10));
            }

            setState(() {
              angle = 0;
            });
          },
          child: ListenableBuilder(
            listenable: drone.pitchesNotifier,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (drone.pitches.isNotEmpty)
                    SizedBox.square(
                      dimension: (widget.radius - 48) * 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          buildPlayButton(),
                          const SizedBox(height: 4),
                          buildResetButton(),
                        ],
                      ),
                    ),
                  for (final Pitch pitch in pitches) buildPitchButton(pitch),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildPlayButton() {
    return ValueListenableBuilder(
      valueListenable: drone.isPlayingNotifier,
      builder: (context, isPlaying, _) => IconButton.filled(
        onPressed: isPlaying ? drone.pause : drone.play,
        icon: Icon(
          isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 75,
        ),
      ),
    );
  }

  Widget buildResetButton() {
    return OutlinedButton.icon(
      onPressed: () {
        drone.pitchesNotifier.clear();
      },
      label: const Text("Reset"),
      icon: const Icon(Icons.refresh),
    );
  }

  Widget buildPitchButton(Pitch pitch) {
    final int index = pitch.semitonesTo(drone.root).abs();
    final double buttonAngle = index * 2 * pi / 12 - pi / 2 + angle;

    final DroneButtonType type = pitch.pitchClass == drone.root.pitchClass
        ? DroneButtonType.root
        : Key.major(drone.root.pitchClass).notes.contains(pitch.pitchClass)
            ? DroneButtonType.diatonic
            : DroneButtonType.chromatic;

    Color backgroundColor = switch (type) {
      DroneButtonType.root => Theme.of(context).colorScheme.primary,
      DroneButtonType.diatonic =>
        Theme.of(context).colorScheme.primaryContainer,
      DroneButtonType.chromatic =>
        Theme.of(context).colorScheme.surfaceContainerHigh
    };
    Color textColor = switch (type) {
      DroneButtonType.root => Theme.of(context).colorScheme.onPrimary,
      DroneButtonType.diatonic =>
        Theme.of(context).colorScheme.onPrimaryContainer,
      DroneButtonType.chromatic => Theme.of(context).colorScheme.onSurface
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
