import 'package:flutter/material.dart';
import 'package:musbx/editable_screen/card_list.dart';
import 'package:musbx/music_player/position_card/button_panel.dart';
import 'package:musbx/music_player/current_song_card/current_song_label.dart';
import 'package:musbx/music_player/labeled_slider.dart';
import 'package:musbx/music_player/loop_card/loop_buttons.dart';
import 'package:musbx/music_player/loop_card/loop_slider.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/position_card/position_slider.dart';

class MusicPlayerScreen extends StatelessWidget {
  /// Screen that allows the user to select and play a song.
  ///
  /// Includes:
  ///  - Buttons to play/pause, forward and rewind.
  ///  - Slider for seeking a position in the song.
  ///  - Sliders for changing pitch and speed of the song.
  ///  - Label showing current song, and button to load a song from device.
  MusicPlayerScreen({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return CardList(
      children: [
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
        Column(children: const [
          LoopButtons(),
          LoopSlider(),
        ]),
        Column(
          children: [
            PositionSlider(),
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
          onChanged: musicPlayer.setPitchSemitones,
        ),
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
          onChanged: musicPlayer.setSpeed,
        ),
      ),
    );
  }
}
