import 'package:flutter/material.dart';
import 'package:musbx/music_player/equalizer/equalizer_card.dart';
import 'package:musbx/music_player/loop_card/loop_card.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/pitch_speed_card/pitch_speed_card.dart';
import 'package:musbx/music_player/position_card/button_panel.dart';
import 'package:musbx/music_player/current_song_card/current_song_panel.dart';
import 'package:musbx/music_player/position_card/position_slider.dart';
import 'package:musbx/screen/card_list.dart';
import 'package:musbx/screen/default_app_bar.dart';
import 'package:musbx/screen/empty_tab_bar.dart';
import 'package:musbx/screen/widget_card.dart';

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
      builder: (context, state, _) => Scaffold(
        appBar: const DefaultAppBar(
          helpText: """Load song from device or YouTube.
Adjust pitch and speed using the circular sliders. While selecting, greater accuracy can be obtained by dragging away from the center.
If looping is enabled, change what section to loop using the range slider. Use the arrows to set the start or end of the section to the current position.""",
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const EmptyTabBar(),
              WidgetCard(
                child: Column(
                  children: [
                    CurrentSongPanel(),
                    PositionSlider(),
                    ButtonPanel(),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    CardList(
                      children: [
                        PitchSpeedCard(),
                        LoopCard(),
                      ],
                    ),
                    CardList(
                      children: [EqualizerCard()],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
