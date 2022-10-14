import 'package:flutter/material.dart';
import 'package:musbx/editable_screen/card_list.dart';
import 'package:musbx/music_player/pitch_speed_card.dart';
import 'package:musbx/music_player/position_card/button_panel.dart';
import 'package:musbx/music_player/current_song_card/current_song_label.dart';
import 'package:musbx/music_player/loop_card/loop_buttons.dart';
import 'package:musbx/music_player/loop_card/loop_slider.dart';
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

  @override
  Widget build(BuildContext context) {
    return CardList(
      children: [
        const CurrentSongPanel(),
        PitchSpeedCard(),
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
}
