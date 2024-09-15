import 'dart:math';

import 'package:flutter/material.dart' hide Key;
import 'package:musbx/drone/drone.dart';
import 'package:musbx/model/key.dart';
import 'package:musbx/model/pitch_class.dart';

enum DroneButtonType {
  /// This pitch is the current root.
  root,

  /// This pitch belongs to the root's major key.
  diatonic,

  /// This pitch is not in the root's major key.
  chromatic,
}

class DroneWheel extends StatefulWidget {
  /// A wheel with buttons that create drone tones in the chromatic scale starting from the [Drone]'s root.
  const DroneWheel({super.key, this.radius = 150});

  /// The radius of the wheel.
  final double radius;

  @override
  State<StatefulWidget> createState() => DroneWheelState();
}

class DroneWheelState extends State<DroneWheel> {
  final Drone drone = Drone.instance;

  /// The current rotation angle
  double angle = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) => SizedBox.square(
        dimension: constraints.biggest.shortestSide,
        child: GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            Offset center = Offset(
                constraints.biggest.width / 2, constraints.biggest.height / 2);
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
            // Smoothly snap the root to the top
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
            listenable: drone.rootNotifier,
            builder: (context, child) => ListenableBuilder(
              listenable: drone.intervalsNotifier,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (drone.intervals.isNotEmpty)
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
                    ...List.generate(12, buildPitchButton),
                  ],
                );
              },
            ),
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
        drone.intervalsNotifier.clear();
      },
      label: const Text("Reset"),
      icon: const Icon(Icons.refresh),
    );
  }

  Widget buildPitchButton(int interval) {
    final PitchClass pitchClass = drone.root.pitchClass.transposed(interval);
    final double buttonAngle = interval * 2 * pi / 12 - pi / 2 + angle;

    final DroneButtonType type = interval == 0
        ? DroneButtonType.root
        : KeyType.major.intervalPattern.contains(interval)
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

    final bool isPlaying = drone.intervals.contains(interval);

    return Transform.translate(
      offset: Offset(cos(buttonAngle), sin(buttonAngle)) * widget.radius,
      child: FloatingActionButton(
        elevation: isPlaying ? 0 : 6,
        backgroundColor:
            isPlaying ? backgroundColor.withOpacity(0.5) : backgroundColor,
        onPressed: () {
          if (isPlaying) {
            drone.intervalsNotifier.remove(interval);
          } else {
            drone.intervalsNotifier.add(interval);
            drone.play();
          }
        },
        child: Text(
          pitchClass.abbreviation,
          style: TextStyle(
            color: textColor,
          ),
        ),
      ),
    );
  }
}
