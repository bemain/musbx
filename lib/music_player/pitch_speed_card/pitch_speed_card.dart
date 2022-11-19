import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/pitch_speed_card/circular_slider/circular_slider.dart';

class PitchSpeedCard extends StatelessWidget {
  /// Card with sliders for changing the pitch and speed of [MusicPlayer].
  ///
  /// Each slider is labeled with max and min value.
  /// Also features a button for resetting pitch and speed to the deafault values.
  PitchSpeedCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: Align(
          alignment: Alignment.topRight,
          child: buildResetButton(),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildPitchSlider(),
          buildSpeedSlider(),
        ],
      ),
    ]);
  }

  Widget buildPitchSlider() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.pitchSemitonesNotifier,
      builder: (context, pitch, _) => Stack(children: [
        CircularSlider(
          value: pitch,
          min: -9,
          max: 9,
          // divisions: 18,
          label: Text(
            ((pitch >= 0) ? "+" : "") + pitch.toStringAsFixed(1),
            style: const TextStyle(fontSize: 25),
          ),
          onChanged: musicPlayer.nullIfNoSongElse(
            musicPlayer.setPitchSemitones,
          ),
        ),
        const Positioned.fill(
          child: Align(
            alignment: Alignment(0, 0.75),
            child: Text("Pitch"),
          ),
        ),
      ]),
    );
  }

  Widget buildSpeedSlider() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.speedNotifier,
      builder: (context, speed, _) => Stack(children: [
        CircularSlider(
          value: speed,
          min: 0.1,
          max: 1.9,
          // divisions: 18,
          label: Text(
            speed.toStringAsFixed(2),
            style: const TextStyle(fontSize: 25),
          ),
          onChanged: musicPlayer.nullIfNoSongElse(
            musicPlayer.setSpeed,
          ),
        ),
        const Positioned.fill(
          child: Align(
            alignment: Alignment(0, 0.75),
            child: Text("Speed"),
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
          onPressed: (speed.toStringAsFixed(2) == "1.00" && pitch == 0)
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
