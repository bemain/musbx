import 'package:flutter/material.dart';
import 'package:musbx/music_player/library_page.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/song_page.dart';
import 'package:musbx/purchases.dart';
import 'package:musbx/widgets.dart';

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
  const MusicPlayerPage({super.key});

  @override
  State<StatefulWidget> createState() => MusicPlayerPageState();
}

class MusicPlayerPageState extends State<MusicPlayerPage>
    with AutomaticKeepAliveClientMixin {
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
        switch (state) {
          case MusicPlayerState.idle:
            return LibraryPage();

          case MusicPlayerState.pickingAudio:
          case MusicPlayerState.loadingAudio:
            return const LoadingPage(text: "Loading song...");

          case MusicPlayerState.ready:
            return DefaultTabController(
              length: 2,
              initialIndex: 0,
              animationDuration: const Duration(milliseconds: 200),
              child: ValueListenableBuilder(
                valueListenable: Purchases.hasPremiumNotifier,
                builder: (context, hasPremium, child) {
                  return const SongPage();
                },
              ),
            );
        }
      },
    );
  }
}
