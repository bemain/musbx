import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/slowdowner/circular_slider/circular_slider.dart';

class SlowdownerCard extends StatelessWidget {
  /// Card with sliders for changing the pitch and speed of [MusicPlayer].
  ///
  /// Each slider is labeled with max and min value.
  /// Also features a button for resetting pitch and speed to the default values.
  SlowdownerCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.slowdowner.enabledNotifier,
      builder: (context, loopEnabled, _) => Stack(children: [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: LayoutBuilder(
            builder: (context, BoxConstraints constraints) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Don't show pitch slider on iOS since setPitch() method is not implemented.
                if (!Platform.isIOS) buildPitchSlider(constraints.maxWidth / 4),
                buildSpeedSlider(constraints.maxWidth / 4),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: loopEnabled,
            onChanged: musicPlayer.nullIfNoSongElse(
              (value) => musicPlayer.slowdowner.enabled = value,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: buildResetButton(),
        ),
      ]),
    );
  }

  Widget buildPitchSlider(double radius) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.slowdowner.pitchSemitonesNotifier,
      builder: (context, pitch, _) => Stack(children: [
        CircularSlider(
          value: pitch,
          min: -12,
          max: 12,
          divisionValues: List.generate(25, (i) => i - 12.0),
          outerRadius: radius,
          label: Text(
            ((pitch >= 0) ? "+" : "-") + pitch.abs().toStringAsFixed(1),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          onChanged: musicPlayer.nullIfNoSongElse(
            (!musicPlayer.slowdowner.enabled)
                ? null
                : (double value) {
                    musicPlayer.slowdowner
                        .setPitchSemitones((value * 10).roundToDouble() / 10);
                  },
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.8),
            child: Text(
              "Pitch",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ]),
    );
  }

  Widget buildSpeedSlider(double radius) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.slowdowner.speedNotifier,
      builder: (context, speed, _) => Stack(children: [
        CircularSlider(
          value: sqrt(speed - 7 / 16) - 0.25,
          min: 0,
          max: 1,
          divisionValues: List.generate(
                  21, (i) => (i <= 10) ? 0.5 + i / 20 : 0.5 - 10 / 20 + i / 10)
              .map((speedValue) => sqrt(speedValue - 7 / 16) - 0.25)
              .toList(),
          outerRadius: radius,
          label: Text(
            speed.toStringAsFixed(2),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          onChanged: musicPlayer.nullIfNoSongElse(
            (!musicPlayer.slowdowner.enabled)
                ? null
                : (double value) {
                    musicPlayer.slowdowner
                        .setSpeed(pow(value, 2) + value / 2 + 0.5);
                  },
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.8),
            child: Text(
              "Speed",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ]),
    );
  }

  Widget buildResetButton() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.slowdowner.speedNotifier,
      builder: (_, speed, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.slowdowner.pitchSemitonesNotifier,
        builder: (context, pitch, _) => IconButton(
          iconSize: 20,
          onPressed: (speed.toStringAsFixed(2) == "1.00" &&
                  pitch.abs().toStringAsFixed(1) == "0.0")
              ? null
              : () {
                  musicPlayer.slowdowner.setSpeed(1.0);
                  musicPlayer.slowdowner.setPitchSemitones(0);
                },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    );
  }
}
