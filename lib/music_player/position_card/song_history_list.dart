import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/song.dart';

class SongHistoryList extends StatelessWidget {
  /// Widget displaying the previously played songs as buttons.
  ///
  /// Pressing a song button tells [MusicPlayer] to load that song.
  SongHistoryList({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: (musicPlayer.songHistory.sorted(ascending: false)
                ..remove(musicPlayer.song))
              .map(_buildSongButton)
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSongButton(Song song) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: musicPlayer.isLoading
            ? null
            : () {
                musicPlayer.loadSong(song);
              },
        child: Text(song.title),
      ),
    );
  }
}
