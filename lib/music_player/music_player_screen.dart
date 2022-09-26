import 'package:flutter/material.dart';
import 'package:musbx/editable_screen.dart';
import 'package:musbx/music_player/button_panel.dart';
import 'package:musbx/music_player/current_song_panel.dart';
import 'package:musbx/music_player/stream_slider.dart';
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
              " Pitch",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            buildPitchSlider(),
            Text(
              "  Speed",
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
    return StreamSlider(
      listenable: musicPlayer.pitchSemitonesNotifier,
      onChangeEnd: (double value) {
        musicPlayer.setPitchSemitones(value);
      },
      onClear: () {
        musicPlayer.setPitchSemitones(0);
      },
      min: -9,
      max: 9,
      initialValue: MusicPlayer.instance.pitchSemitonesNotifier.value,
      divisions: 18,
      labelFractionDigits: 0,
    );
  }

  Widget buildSpeedSlider() {
    return StreamSlider(
      listenable: musicPlayer.speedNotifier,
      onChangeEnd: (double value) {
        musicPlayer.setSpeed(value);
      },
      onClear: () {
        musicPlayer.setSpeed(1.0);
      },
      min: 0.1,
      max: 1.9,
      initialValue: MusicPlayer.instance.speedNotifier.value,
      divisions: 18,
      labelFractionDigits: 1,
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
                  max: duration?.inSeconds.roundToDouble() ?? 1,
                  value: position.inSeconds.roundToDouble(),
                  onChanged: (double value) {
                    musicPlayer.seek(Duration(seconds: value.round()));
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
