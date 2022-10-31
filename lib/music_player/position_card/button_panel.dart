import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class ButtonPanel extends StatelessWidget {
  /// Panel including play/pause, forward and rewind buttons for controlling [MusicPlayer].
  ///
  /// If no song is loaded, all buttons are disabled.
  ButtonPanel({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: musicPlayer.nullIfNoSongElse(() {
            musicPlayer.seek(musicPlayer.position - const Duration(seconds: 1));
          }),
          onLongPress: musicPlayer.nullIfNoSongElse(() {
            musicPlayer.seek(Duration.zero);
          }),
          child: const Icon(Icons.fast_rewind_rounded, size: 40),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: musicPlayer.isPlayingNotifier,
          builder: (context, isPlaying, child) {
            return TextButton(
              onPressed: musicPlayer.nullIfNoSongElse(() {
                if (isPlaying) {
                  musicPlayer.pause();
                } else {
                  musicPlayer.play();
                }
              }),
              child: (musicPlayer.state == MusicPlayerState.loadingAudio)
                  ? const Padding(
                      padding: EdgeInsets.all(19.5),
                      child: CircularProgressIndicator())
                  : Icon(
                      isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 75,
                    ),
            );
          },
        ),
        TextButton(
          onPressed: musicPlayer.nullIfNoSongElse(() {
            musicPlayer.seek(musicPlayer.position + const Duration(seconds: 1));
          }),
          child: const Icon(Icons.fast_forward_rounded, size: 40),
        ),
      ],
    );
  }
}
