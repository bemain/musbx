import 'package:flutter/material.dart';
import 'package:musbx/music_player/current_song_card/pick_song_button.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/current_song_card/youtube_button.dart';

class CurrentSongPanel extends StatelessWidget {
  /// Panel displaying the currently loaded song, with buttons to load a new song,
  /// from a local file or from YouTube.
  CurrentSongPanel({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Currently playing:",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  currentSongLabel(),
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PickSongButton(),
        Container(width: 10),
        YoutubeButton(),
      ],
    );
  }

  /// Generate a text label based on [musicPlayer.state].
  String currentSongLabel() {
    switch (musicPlayer.state) {
      case MusicPlayerState.idle:
        return "(No song loaded)";
      case MusicPlayerState.pickingAudio:
      case MusicPlayerState.loadingAudio:
        return "(Loading song...)";
      case MusicPlayerState.ready:
        return musicPlayer.song!.title;
    }
  }
}
