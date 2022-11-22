import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider/circular_slider.dart';

class PitchSpeedCard extends StatelessWidget {
  /// Card with sliders for changing the pitch and speed of [MusicPlayer].
  ///
  /// Each slider is labeled with max and min value.
  /// Also features a button for resetting pitch and speed to the default values.
  PitchSpeedCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.only(top: 10),
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
      Positioned.fill(
        child: Align(
          alignment: Alignment.topCenter,
          child: buildResetButton(),
        ),
      ),
    ]);
  }

  Widget buildPitchSlider(double radius) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.pitchSemitonesNotifier,
      builder: (context, pitch, _) => Stack(children: [
        CircularSlider(
          value: pitch,
          min: -12,
          max: 12,
          divisions: 24,
          outerRadius: radius,
          label: Text(
            ((pitch >= 0) ? "+" : "-") + pitch.abs().toStringAsFixed(1),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          onChanged: musicPlayer.nullIfNoSongElse(
            (double value, bool continuous) {
              if (continuous) {
                value = value.roundToDouble();
              } else {
                value = (value * 10).roundToDouble() / 10;
              }
              musicPlayer.setPitchSemitones(value);
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
      valueListenable: musicPlayer.speedNotifier,
      builder: (context, speed, _) => Stack(children: [
        CircularSlider(
          value: speed,
          min: 0.1,
          max: 1.9,
          divisions: 18,
          outerRadius: radius,
          label: Text(
            speed.toStringAsFixed(2),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          onChanged: musicPlayer.nullIfNoSongElse(
            (double value, bool continuous) {
              if (continuous) {
                value = (value * 10).roundToDouble() / 10;
              }
              musicPlayer.setSpeed(value);
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
      valueListenable: musicPlayer.speedNotifier,
      builder: (_, speed, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.pitchSemitonesNotifier,
        builder: (context, pitch, _) => IconButton(
          iconSize: 20,
          onPressed: (speed.toStringAsFixed(2) == "1.00" &&
                  pitch.abs().toStringAsFixed(1) == "0.0")
              ? null
              : () {
                  musicPlayer.setSpeed(1.0);
                  musicPlayer.setPitchSemitones(0);
                },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    );
  }
}
