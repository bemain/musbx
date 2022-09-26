import 'package:flutter/material.dart';
import 'package:musbx/editable_screen.dart';
import 'package:musbx/music_player/button_panel.dart';
import 'package:musbx/music_player/current_song_panel.dart';
import 'package:musbx/music_player/labeled_slider.dart';
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
  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return EditableScreen(
      title: "Music Player",
      widgets: [
        const CurrentSongPanel(),
        Column(
          children: [
            Text(
              "Pitch",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            buildPitchSlider(),
            Text(
              "Speed",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            buildSpeedSlider(),
          ],
        ),
        Column(
          children: [
            buildPositionSlider(),
            const ButtonPanel(),
          ],
        ),
      ],
    );
  }

  Widget buildPitchSlider() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.pitchSemitonesNotifier,
      builder: (context, pitch, child) => LabeledSlider(
        value: pitch,
        nDigits: 0,
        clearDisabled: pitch == 0,
        onClear: () {
          musicPlayer.setPitchSemitones(0);
        },
        child: Slider(
            value: pitch,
            min: -9,
            max: 9,
            divisions: 18,
            onChanged: musicPlayer.setPitchSemitones),
      ),
    );
  }

  Widget buildSpeedSlider() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.speedNotifier,
      builder: (context, speed, child) => LabeledSlider(
        value: speed,
        nDigits: 1,
        clearDisabled: speed == 1.0,
        onClear: () {
          musicPlayer.setSpeed(1.0);
        },
        child: Slider(
            value: speed,
            min: 0.1,
            max: 1.9,
            divisions: 18,
            onChanged: musicPlayer.setSpeed),
      ),
    );
  }

  Widget buildPositionSlider() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (context, duration, child) => ValueListenableBuilder(
        valueListenable: musicPlayer.positionNotifier,
        builder: (context, position, child) {
          return Row(
            children: [
              _buildDurationText(position),
              Expanded(
                child: Slider(
                  min: 0,
                  max: duration?.inMilliseconds.roundToDouble() ?? 0,
                  value: position.inMilliseconds.roundToDouble(),
                  onChanged: (musicPlayer.songTitle == null)
                      ? null
                      : (double value) {
                          musicPlayer
                              .seek(Duration(milliseconds: value.round()));
                        },
                ),
              ),
              _buildDurationText(duration),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDurationText(Duration? duration) {
    return Text(
      (duration == null)
          ? "-- : --"
          : RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                  .firstMatch("$duration")
                  ?.group(1) ??
              "$duration",
      style: Theme.of(context).textTheme.caption,
    );
  }
}
