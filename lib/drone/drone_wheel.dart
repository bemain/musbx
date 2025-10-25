import 'dart:math';

import 'package:flutter/material.dart' hide Key;
import 'package:material_symbols_icons/symbols.dart';
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
  const DroneWheel({super.key, this.elasticity = 2.0});

  /// The strength of the contracting force applied when the wheel is at the minimum or maximum value,
  /// and when the user lets go and the root moves to the top.
  final double elasticity;

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
      builder: (context, constraints) {
        final double radius = constraints.biggest.shortestSide / 2 - 48;

        return SizedBox.square(
          dimension: constraints.biggest.shortestSide,
          child: GestureDetector(
            onPanUpdate: (details) {
              Offset center = Offset(
                constraints.biggest.shortestSide / 2,
                constraints.biggest.shortestSide / 2,
              );
              Offset a = details.localPosition - center;
              Offset b = (details.localPosition - details.delta) - center;

              final double deltaAngle = atan2(
                a.dx * b.dy - a.dy * b.dx,
                a.dx * b.dx + a.dy * b.dy,
              );

              setState(() {
                final int semitones = -(12 * angle / (2 * pi)).round();
                final int targetSemitonesFromC0 =
                    drone.root.octave * 12 +
                    drone.root.pitchClass.semitonesFromC +
                    semitones;

                if (targetSemitonesFromC0 < Drone.minOctave * 12 ||
                    targetSemitonesFromC0 > Drone.maxOctave * 12 + 11) {
                  angle -= deltaAngle / (angle.abs() * widget.elasticity + 1);
                  return;
                }

                angle -= deltaAngle;

                if (semitones != 0) {
                  drone.rootStepNotifier.value += semitones;
                  angle += semitones * 2 * pi / 12;
                }
              });
            },
            onPanEnd: (details) async {
              // Smoothly snap the root to the top
              for (int i = 0; i < 10; i++) {
                setState(() {
                  angle /= widget.elasticity;
                });
                await Future<void>.delayed(const Duration(milliseconds: 10));
              }

              setState(() {
                angle = 0;
              });
            },
            child: ListenableBuilder(
              listenable: drone.rootStepNotifier,
              builder: (context, child) => ListenableBuilder(
                listenable: drone.intervalsNotifier,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (drone.intervals.isNotEmpty)
                        SizedBox.square(
                          dimension: (radius - 48) * 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              buildPlayButton(),
                              const SizedBox(height: 4),
                              buildResetButton(),
                            ],
                          ),
                        ),
                      ...List.generate(
                        12,
                        (index) => buildPitchButton(index, radius),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildPlayButton() {
    return ValueListenableBuilder(
      valueListenable: drone.isPlayingNotifier,
      builder: (context, isPlaying, _) => IconButton.filled(
        onPressed: isPlaying ? drone.pause : drone.resume,
        iconSize: 75,
        icon: Icon(
          isPlaying ? Symbols.stop_rounded : Symbols.play_arrow_rounded,
          fill: 1,
        ),
      ),
    );
  }

  Widget buildResetButton() {
    return IconButton(
      onPressed: () {
        drone.intervalsNotifier.value = [];
      },
      icon: const Icon(Symbols.refresh),
    );
  }

  Widget buildPitchButton(int interval, double radius) {
    final PitchClass pitchClass = drone.root.pitchClass.transposed(interval);
    final double buttonAngle = interval * 2 * pi / 12 - pi / 2 + angle;

    final DroneButtonType type = interval == 0
        ? DroneButtonType.root
        : KeyType.major.intervalPattern.contains(interval)
        ? DroneButtonType.diatonic
        : DroneButtonType.chromatic;

    Color backgroundColor = switch (type) {
      DroneButtonType.root => Theme.of(context).colorScheme.primary,
      DroneButtonType.diatonic => Theme.of(
        context,
      ).colorScheme.primaryContainer,
      DroneButtonType.chromatic => Theme.of(
        context,
      ).colorScheme.surfaceContainerHigh,
    };
    Color textColor = switch (type) {
      DroneButtonType.root => Theme.of(context).colorScheme.onPrimary,
      DroneButtonType.diatonic => Theme.of(
        context,
      ).colorScheme.onPrimaryContainer,
      DroneButtonType.chromatic => Theme.of(context).colorScheme.onSurface,
    };

    final bool isPlaying = drone.intervals.contains(interval);

    return Transform.translate(
      offset: Offset(cos(buttonAngle), sin(buttonAngle)) * radius,
      child: FloatingActionButton(
        heroTag: "drone-pitch-$interval",
        elevation: isPlaying ? 0 : 6,
        backgroundColor: isPlaying
            ? backgroundColor.withAlpha(0x61)
            : backgroundColor,
        onPressed: () {
          if (isPlaying) {
            drone.intervals = drone.intervals
                .where((i) => i != interval)
                .toList();
          } else {
            drone.intervals = [...drone.intervals, interval];
            drone.resume();
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
