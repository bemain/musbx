import 'package:flutter/material.dart';
import 'package:musbx/music_player/current_song_card/pick_song_button.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/current_song_card/youtube_button.dart';

class CurrentSongPanel extends StatelessWidget {
  /// Panel displaying the currently loaded song, with buttons to load a new song,
  /// from a local file or from YouTube (WIP)
  const CurrentSongPanel({super.key});

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
                style: Theme.of(context).textTheme.caption,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: ValueListenableBuilder<String?>(
                  valueListenable: MusicPlayer.instance.songTitleNotifier,
                  builder: (context, songTitle, child) => Text(
                    songTitle ?? "(No song loaded)",
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        const PickSongButton(),
        Container(width: 10),
        const YoutubeButton(),
      ],
    );
  }
}
