import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer_card.dart';
import 'package:musbx/music_player/equalizer/equalizer_card.dart';
import 'package:musbx/music_player/looper/loop_card.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/slowdowner/slowdowner_card.dart';
import 'package:musbx/music_player/position_card/button_panel.dart';
import 'package:musbx/music_player/current_song_card/current_song_panel.dart';
import 'package:musbx/music_player/position_card/position_slider.dart';
import 'package:musbx/music_player/current_song_card/song_history_list.dart';
import 'package:musbx/screen/card_list.dart';
import 'package:musbx/screen/default_app_bar.dart';
import 'package:musbx/screen/widget_card.dart';

class MusicPlayerScreen extends StatefulWidget {
  /// Screen that allows the user to select and play a song.
  ///
  /// Includes:
  ///  - Label showing current song, and button to load a song from device.
  ///  - Buttons to play/pause, forward and rewind.
  ///  - Slider for seeking a position in the song.
  ///  - Sliders for changing pitch and speed of the song.
  ///  - Slider and buttons for looping a section of the song.
  ///  - Controls for the Demixer.
  ///  - Controls for the Equalizer.
  const MusicPlayerScreen({super.key});

  @override
  State<StatefulWidget> createState() => MusicPlayerScreenState();
}

class MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    MusicPlayer.instance.saveSongPreferences();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save preferences for the current song
    if (state == AppLifecycleState.paused) {
      MusicPlayer.instance.saveSongPreferences();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder(
        valueListenable: MusicPlayer.instance.stateNotifier,
        builder: (context, state, _) {
          List<Widget> tabs = [
            CardList(
              children: [
                SlowdownerCard(),
                LoopCard(),
              ],
            ),
            CardList(
              children: [DemixerCard()],
            ),
            if (!Platform.isIOS)
              CardList(
                children: [EqualizerCard()],
              ),
          ];

          return Scaffold(
            appBar: DefaultAppBar(
              helpText: """Load song from device or YouTube.
The Slowdowner allows you to adjust pitch and speed using the circular sliders. While selecting, greater accuracy can be obtained by dragging away from the center.
Change what section to loop using the range slider. Use the arrows to set the start or end of the section to the current position.
Mute or isolate specific instruments using the Demixer.
${Platform.isAndroid ? "Use the Equalizer to adjust the gain of individual frequency bands." : ""}""",
            ),
            body: DefaultTabController(
              length: tabs.length,
              child: Column(
                children: [
                  if (tabs.length > 1)
                    TabBar(tabs: [
                      const Tab(text: "Slowdowner"),
                      const Tab(text: "Demixer"),
                      if (!Platform.isIOS) const Tab(text: "Equalizer"),
                    ]),
                  WidgetCard(
                    child: Column(children: [
                      CurrentSongPanel(),
                      const SongHistoryList(),
                    ]),
                  ),
                  WidgetCard(
                    child: Column(children: [
                      PositionSlider(),
                      ButtonPanel(),
                    ]),
                  ),
                  Expanded(
                    child: TabBarView(children: tabs),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
