import 'package:flutter/material.dart';
import 'package:musbx/card_list.dart';
import 'package:musbx/music_player/music_player.dart';
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
  ///  - Slider and buttons for looping a section of the song.
  const MusicPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: MusicPlayer.instance.stateNotifier,
      builder: (context, state, _) => CardList(
        helpText: """Load song from device or YouTube.
Adjust pitch and speed using the sliders.
If looping is enabled, change what section to loop using the range slider. Use the arrows to set the start or end of the section to the current position.
Long press rewind button to restart song.""",
        children: [
          CurrentSongPanel(),
          PitchSpeedCard(),
          Column(children: [
            LoopButtons(),
            LoopSlider(),
          ]),
          Column(
            children: [
              PositionSlider(),
              ButtonPanel(),
            ],
          ),
        ],
      ),
    );
  }
}
