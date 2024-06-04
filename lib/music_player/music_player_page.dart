import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musbx/custom_icons.dart';
import 'package:musbx/music_player/demixer/demixer_card.dart';
import 'package:musbx/music_player/equalizer/equalizer_card.dart';
import 'package:musbx/music_player/exception_dialogs.dart';
import 'package:musbx/music_player/looper/loop_card.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/pick_song_button/components/spacer.dart';
import 'package:musbx/music_player/pick_song_button/components/search_youtube_button.dart';
import 'package:musbx/music_player/pick_song_button/components/upload_file_button.dart';
import 'package:musbx/music_player/slowdowner/slowdowner_card.dart';
import 'package:musbx/music_player/bottom_bar/button_panel.dart';
import 'package:musbx/music_player/bottom_bar/current_song_panel.dart';
import 'package:musbx/music_player/bottom_bar/position_slider.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';
import 'package:musbx/music_player/pick_song_button/speed_dial.dart';
import 'package:musbx/music_player/pick_song_button/components/action.dart';
import 'package:musbx/page/bottom_bar.dart';
import 'package:musbx/page/default_app_bar.dart';
import 'package:musbx/page/widget_card.dart';
import 'package:musbx/widgets.dart';

/// The key of the [MusicPlayerPage]. Can be used to show dialogs.
final GlobalKey<MusicPlayerPageState> musicPlayerPageKey = GlobalKey();

class MusicPlayerPage extends StatefulWidget {
  /// Page that allows the user to select and play a song.
  ///
  /// Includes:
  ///  - Label showing current song, and button to load a song from device.
  ///  - Buttons to play/pause, forward and rewind.
  ///  - Slider for seeking a position in the song.
  ///  - Sliders for changing pitch and speed of the song.
  ///  - Slider and buttons for looping a section of the song.
  ///  - Controls for the Demixer.
  ///  - Controls for the Equalizer.
  MusicPlayerPage() : super(key: musicPlayerPageKey);

  @override
  State<StatefulWidget> createState() => MusicPlayerPageState();
}

class MusicPlayerPageState extends State<MusicPlayerPage>
    with AutomaticKeepAliveClientMixin {
  static const String helpText =
      """Press the plus-button and load a song from your device or YouTube.

- Adjust pitch and speed using the circular sliders. Greater accuracy can be obtained by dragging away from the center.
- Loop a section of the song using the range slider. Use the arrows to set the start or end of the section to the current position.
- Mute or isolate specific instruments using the Demixer.""";

  @override
  bool get wantKeepAlive => true;

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  Size? bottomBarSize;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder(
      valueListenable: musicPlayer.stateNotifier,
      builder: (context, state, _) {
        return state == MusicPlayerState.idle
            ? _buildWelcomePage(context)
            : Scaffold(
                body: ListView(
                  children: [
                    const DefaultAppBar(
                      scrolledUnderElevation: 0.0,
                      helpText:
                          """Press the plus-button and load a song from your device or YouTube.

- Adjust pitch and speed using the circular sliders. Greater accuracy can be obtained by dragging away from the center.
- Loop a section of the song using the range slider. Use the arrows to set the start or end of the section to the current position.
- Mute or isolate specific instruments using the Demixer.""",
                    ),
                    WidgetCard(child: SlowdownerCard()),
                    WidgetCard(child: LoopCard()),
                    WidgetCard(child: DemixerCard()),
                    if (Platform.isAndroid) WidgetCard(child: EqualizerCard()),
                    if (bottomBarSize != null)
                      SizedBox(height: bottomBarSize!.height + 4.0)
                  ],
                ),
                bottomSheet: MeasureSize(
                  onSizeChanged: (Size size) {
                    setState(() {
                      bottomBarSize = size;
                    });
                  },
                  child: BottomBar(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CurrentSongPanel(),
                        PositionSlider(),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ButtonPanel(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _buildLoadSongButton(),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
      },
    );
  }

  Widget _buildWelcomePage(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(helpText: helpText),
      floatingActionButton: _buildLoadSongButton(heroTag: "welcome-speed-dial"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Prepare to",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              "Transcribe",
              style: GoogleFonts.zeyadaTextTheme(Theme.of(context).textTheme)
                  .displayLarge,
            ),
            Text(
              "using AI technology",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text("Press the"), Icon(Icons.add), Text("to begin")],
            ),
            const SizedBox(height: 64.0),
            Padding(
              padding: const EdgeInsets.only(left: 70),
              child: Image.asset(
                "assets/images/arrow.png",
                width: 100,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 64.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadSongButton({Object? heroTag}) {
    final List<Song> songHistory = musicPlayer.songHistory
        .sorted(ascending: true)
      ..remove(musicPlayer.song);

    return SpeedDial(
      heroTag: heroTag,
      children: [
        ...(songHistory).map(_buildHistoryItem).toList(),
        if (songHistory.isNotEmpty) SpeedDialSpacer(),
        UploadSongButton(),
      ],
      onExpandedPressed: MusicPlayer.instance.isLoading
          ? null
          : () async {
              await pickYoutubeSong(context);
            },
      expandedChild: const Icon(Icons.search),
      expandedLabel: const Text("Search YouTube"),
      child: const Icon(Icons.add),
    );
  }

  SpeedDialChild _buildHistoryItem(Song song) {
    return SpeedDialAction(
      onPressed: musicPlayer.isLoading
          ? null
          : (event) async {
              MusicPlayerState prevState = musicPlayer.state;
              musicPlayer.stateNotifier.value = MusicPlayerState.pickingAudio;
              try {
                await musicPlayer.loadSong(song);
                return;
              } catch (error) {
                showExceptionDialog(
                  song.source is YoutubeSource
                      ? const YoutubeUnavailableDialog()
                      : const FileCouldNotBeLoadedDialog(),
                );
                // Restore state
                musicPlayer.stateNotifier.value = prevState;
                return;
              }
            },
      label: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 2 / 3,
        ),
        child: Text(
          song.title,
          maxLines: 1,
        ),
      ),
      child: _buildSongSourceAvatar(song) ?? Container(),
    );
  }

  Widget? _buildSongSourceAvatar(Song song) {
    if (song.source is FileSource) {
      return const Icon(Icons.file_present);
    }
    if (song.source is YoutubeSource) {
      return const Icon(CustomIcons.youtube);
    }

    return null;
  }
}
