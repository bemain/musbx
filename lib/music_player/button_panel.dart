import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class ButtonPanel extends StatelessWidget {
  /// Panel including play/pause, forward and rewind buttons for controlling [MusicPlayer].
  ///
  /// If no song is loaded, all buttons are disabled.
  const ButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return ValueListenableBuilder(
      valueListenable: musicPlayer.songTitleNotifier,
      builder: (context, songTitle, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: (songTitle == null)
                  ? null
                  : () {
                      musicPlayer.seek(musicPlayer.positionNotifier.value -
                          const Duration(seconds: 1));
                    },
              onLongPress: (songTitle == null)
                  ? null
                  : () {
                      musicPlayer.seek(Duration.zero);
                    },
              child: const Icon(Icons.fast_rewind_rounded, size: 40),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: musicPlayer.isPlayingNotifier,
              builder: (context, isPlaying, child) {
                return TextButton(
                  onPressed: (songTitle == null)
                      ? null
                      : () {
                          if (isPlaying) {
                            musicPlayer.pause();
                          } else {
                            musicPlayer.play();
                          }
                        },
                  child: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 75,
                  ),
                );
              },
            ),
            TextButton(
              onPressed: (songTitle == null)
                  ? null
                  : () {
                      musicPlayer.seek(musicPlayer.positionNotifier.value +
                          const Duration(seconds: 1));
                    },
              child: const Icon(Icons.fast_forward_rounded, size: 40),
            ),
          ],
        );
      },
    );
  }
}
