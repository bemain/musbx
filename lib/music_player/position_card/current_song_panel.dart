import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class CurrentSongPanel extends StatelessWidget {
  /// Panel displaying the currently loaded song, with buttons to load a new song,
  /// from a local file or from YouTube.
  CurrentSongPanel({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
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
