import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/player/music_player.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/circular_slider/circular_slider.dart';
import 'package:musbx/widgets/widgets.dart';

class SlowdownerSheet extends StatelessWidget {
  /// Card with sliders for changing the pitch and speed of [MusicPlayer].
  ///
  /// Each slider is labeled with max and min value.
  /// Also features a button for resetting pitch and speed to the default values.
  SlowdownerSheet({super.key});

  final SongPlayer player = Songs.player!;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(children: [
            Align(
              alignment: Alignment.topCenter,
              child: ValueListenableBuilder(
                valueListenable: player.slowdowner.speedNotifier,
                builder: (_, speed, __) => ValueListenableBuilder(
                  valueListenable: player.slowdowner.pitchNotifier,
                  builder: (context, pitch, _) => IconButton(
                    iconSize: 20,
                    onPressed: (speed.toStringAsFixed(2) == "1.00" &&
                            pitch.abs().toStringAsFixed(1) == "0.0")
                        ? null
                        : () {
                            player.slowdowner.speed = 1.0;
                            player.slowdowner.pitch = 0;
                          },
                    icon: const Icon(Symbols.refresh),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: LayoutBuilder(
                builder: (context, BoxConstraints constraints) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildPitchSlider(constraints.maxWidth / 4),
                    buildSpeedSlider(constraints.maxWidth / 4),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  /// Whether the [player] was playing before the user began changing the pitch or speed.
  static bool wasPlayingBeforeChange = false;

  Widget buildPitchSlider(double radius) {
    return ValueListenableBuilder(
      valueListenable: player.slowdowner.pitchNotifier,
      builder: (context, pitch, _) => Column(children: [
        Text(
          "Pitch",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        CircularSlider(
          value: pitch,
          min: -12,
          max: 12,
          divisionValues: List.generate(25, (i) => i - 12.0),
          outerRadius: radius,
          onChanged: (double value) {
            player.slowdowner.pitch = (value * 10).roundToDouble() / 10;
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: NumberField<double>(
                  value: double.parse(pitch.toStringAsFixed(1)),
                  min: -12.0,
                  max: 12.0,
                  style: Theme.of(context).textTheme.displaySmall,
                  prefixWithSign: true,
                  onSubmitted: (value) {
                    player.slowdowner.pitch = value;
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget buildSpeedSlider(double radius) {
    return ValueListenableBuilder(
      valueListenable: player.slowdowner.speedNotifier,
      builder: (context, speed, _) => Column(children: [
        Text(
          "Speed",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        CircularSlider(
          value: sqrt(speed - 7 / 16) - 0.25,
          min: 0,
          max: 1,
          divisionValues: List.generate(
                  21, (i) => (i <= 10) ? 0.5 + i / 20 : 0.5 - 10 / 20 + i / 10)
              .map((speedValue) => sqrt(speedValue - 7 / 16) - 0.25)
              .toList(),
          outerRadius: radius,
          onChanged: (double value) {
            player.slowdowner.speed = pow(value, 2) + value / 2 + 0.5;
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: NumberField<double>(
                  value: double.parse(speed.toStringAsFixed(2)),
                  min: 0.5,
                  max: 2.0,
                  prefixWithSign: false,
                  style: Theme.of(context).textTheme.displaySmall,
                  inputFormatters: [
                    // Don't allow negative numbers
                    FilteringTextInputFormatter.deny(RegExp(r"-"))
                  ],
                  onSubmitted: (value) {
                    player.slowdowner.speed = value;
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget buildResetButton() {
    return ValueListenableBuilder(
      valueListenable: player.slowdowner.speedNotifier,
      builder: (_, speed, __) => ValueListenableBuilder(
        valueListenable: player.slowdowner.pitchNotifier,
        builder: (context, pitch, _) => IconButton(
          iconSize: 20,
          onPressed: (speed.toStringAsFixed(2) == "1.00" &&
                  pitch.abs().toStringAsFixed(1) == "0.0")
              ? null
              : () {
                  player.slowdowner.speed = 1.0;
                  player.slowdowner.pitch = 0;
                },
          icon: const Icon(Symbols.refresh),
        ),
      ),
    );
  }
}
