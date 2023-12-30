import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:musbx/music_player/position_card/button_panel.dart';
import 'package:musbx/music_player/position_card/current_song_panel.dart';
import 'package:musbx/music_player/position_card/position_slider.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/music_player/song_source.dart';
import 'package:musbx/music_player/pick_song_button/speed_dial.dart';
import 'package:musbx/music_player/pick_song_button/components/action.dart';
import 'package:musbx/screen/default_app_bar.dart';
import 'package:musbx/screen/widget_card.dart';

/// The key of the [MusicPlayerScreen]. Can be used to show dialogs.
final GlobalKey<MusicPlayerScreenState> musicPlayerScreenKey = GlobalKey();

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
  MusicPlayerScreen() : super(key: musicPlayerScreenKey);

  @override
  State<StatefulWidget> createState() => MusicPlayerScreenState();
}

class MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final MusicPlayer musicPlayer = MusicPlayer.instance;

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
      musicPlayer.saveSongPreferences();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder(
      valueListenable: musicPlayer.stateNotifier,
      builder: (context, state, _) {
        final List<Song> songHistory = musicPlayer.songHistory
            .sorted(ascending: true)
          ..remove(musicPlayer.song);

        return Scaffold(
          appBar: DefaultAppBar(
            helpText: """Load song from device or YouTube.
The Slowdowner allows you to adjust pitch and speed using the circular sliders. While selecting, greater accuracy can be obtained by dragging away from the center.
Change what section to loop using the range slider. Use the arrows to set the start or end of the section to the current position.
Mute or isolate specific instruments using the Demixer.
${Platform.isAndroid ? "Use the Equalizer to adjust the gain of individual frequency bands." : ""}""",
          ),
          floatingActionButton: SpeedDial(
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
            expandedChild: const Icon(Icons.search_rounded),
            expandedLabel: const Text("Search Youtube"),
            child: const Icon(Icons.add_rounded),
          ),
          body: Stack(
            children: [
              ListView(
                children: [
                  WidgetCard(child: SlowdownerCard()),
                  WidgetCard(child: LoopCard()),
                  WidgetCard(child: DemixerCard()),
                  WidgetCard(child: EqualizerCard()),
                  const SizedBox(height: 212)
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12.0)),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 3.0,
                  margin: const EdgeInsets.only(top: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CurrentSongPanel(),
                        PositionSlider(),
                        ButtonPanel(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      return const Icon(Icons.file_present_rounded);
    }
    if (song.source is YoutubeSource) {
      return const Icon(CustomIcons.youtube);
    }

    return null;
  }
}
