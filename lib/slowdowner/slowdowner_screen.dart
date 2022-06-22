import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/button_panel.dart';
import 'package:musbx/slowdowner/current_song_panel.dart';
import 'package:musbx/slowdowner/stream_slider.dart';
import 'package:musbx/slowdowner/position_slider.dart';
import 'package:musbx/slowdowner/slowdowner.dart';

class SlowdownerScreen extends StatefulWidget {
  /// Screen that allows the user to select and play a song.
  ///
  /// Inlcudes:
  ///  - Buttons; play/pause, forward, rewind
  ///  - Slider for seeking a position in the song
  ///  - Sliders for changing pitch and speed of the song.
  const SlowdownerScreen({super.key});

  @override
  State<StatefulWidget> createState() => SlowdownerScreenState();
}

class SlowdownerScreenState extends State<SlowdownerScreen> {
  final Slowdowner slowdowner = Slowdowner.instance;

  @override
  void initState() {
    super.initState();

    slowdowner.setAsset("assets/youve_got.mp3");
    slowdowner.songTitle = "You've got a friend in me - Randy Newman";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "Pitch",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        buildPitchSlider(),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "Speed",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        buildSpeedSlider(),
        const Divider(),
        const PositionSlider(),
        const ButtonPanel(),
        const Divider(),
        const CurrentSongPanel(),
      ],
    );
  }

  Widget buildPitchSlider() {
    return StreamSlider(
      stream: slowdowner.pitchStream
          .map((double pitch) => (12 * log(pitch) / log(2)).roundToDouble()),
      onChangeEnd: (double value) {
        slowdowner.setPitchSemitones(value);
      },
      onClear: () {
        slowdowner.setPitchSemitones(0);
      },
      min: -9,
      max: 9,
      startValue: 0,
      divisions: 18,
      labelFractionDigits: 0,
    );
  }

  Widget buildSpeedSlider() {
    return StreamSlider(
      stream: slowdowner.speedStream,
      onChangeEnd: (double value) {
        slowdowner.setSpeed(value);
      },
      onClear: () {
        slowdowner.setSpeed(1.0);
      },
      min: 0.2,
      max: 2,
      startValue: 1.0,
      divisions: 18,
      labelFractionDigits: 1,
    );
  }
}
