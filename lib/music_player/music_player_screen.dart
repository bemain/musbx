import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/button_panel.dart';
import 'package:musbx/music_player/current_song_panel.dart';
import 'package:musbx/music_player/stream_slider.dart';
import 'package:musbx/music_player/position_slider.dart';
import 'package:musbx/music_player/music_player.dart';

class MusicPlayerScreen extends StatefulWidget {
  /// Screen that allows the user to select and play a song.
  ///
  /// Includes:
  ///  - Buttons to play/pause, forward and rewind.
  ///  - Slider for seeking a position in the song.
  ///  - Sliders for changing pitch and speed of the song.
  ///  - Label showing current song, and button to load a song from device.
  const MusicPlayerScreen({super.key});

  @override
  State<StatefulWidget> createState() => MusicPlayerScreenState();
}

class MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final MusicPlayer player = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            " Pitch",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          buildPitchSlider(),
          Text(
            "  Speed",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          buildSpeedSlider(),
          const Divider(),
          const PositionSlider(),
          const ButtonPanel(),
          const Divider(),
          const CurrentSongPanel(),
        ],
      ),
    );
  }

  Widget buildPitchSlider() {
    return StreamSlider(
      stream: player.pitchStream
          .map((double pitch) => (12 * log(pitch) / log(2)).roundToDouble()),
      onChangeEnd: (double value) {
        player.setPitchSemitones(value);
      },
      onClear: () {
        player.setPitchSemitones(0);
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
      stream: player.speedStream,
      onChangeEnd: (double value) {
        player.setSpeed(value);
      },
      onClear: () {
        player.setSpeed(1.0);
      },
      min: 0.1,
      max: 1.9,
      startValue: 1.0,
      divisions: 18,
      labelFractionDigits: 1,
    );
  }
}
