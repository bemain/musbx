import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class ButtonPanel extends StatelessWidget {
  /// Panel including play/pause, forward and rewind buttons for controlling [MusicPlayer].
  const ButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayer player = MusicPlayer.instance;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            player.seek(player.position - const Duration(seconds: 1));
          },
          onLongPress: () {
            player.seek(Duration.zero);
          },
          child: const Icon(Icons.fast_rewind_rounded, size: 40),
        ),
        StreamBuilder<bool>(
          stream: player.playingStream,
          initialData: false,
          builder: (context, snapshot) {
            bool isPlaying = snapshot.data!;
            return TextButton(
              onPressed: (() {
                if (isPlaying) {
                  player.pause();
                } else {
                  player.play();
                }
              }),
              child: Icon(
                isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 75,
              ),
            );
          },
        ),
        TextButton(
          onPressed: () {
            player.seek(player.position + const Duration(seconds: 1));
          },
          child: const Icon(Icons.fast_forward_rounded, size: 40),
        ),
      ],
    );
  }
}
