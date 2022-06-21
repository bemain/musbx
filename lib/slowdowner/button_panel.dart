import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/slowdowner.dart';

class ButtonPanel extends StatelessWidget {
  const ButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            Slowdowner.audioPlayer.seek(
                Slowdowner.audioPlayer.position - const Duration(seconds: 1));
          },
          onLongPress: () {
            Slowdowner.audioPlayer.seek(Duration.zero);
          },
          child: const Icon(Icons.fast_rewind_rounded, size: 40),
        ),
        StreamBuilder<bool>(
          stream: Slowdowner.audioPlayer.playingStream,
          initialData: false,
          builder: (context, snapshot) {
            bool isPlaying = snapshot.data!;
            return TextButton(
              onPressed: (() {
                if (isPlaying) {
                  Slowdowner.audioPlayer.pause();
                } else {
                  Slowdowner.audioPlayer.play();
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
            Slowdowner.audioPlayer.seek(
                Slowdowner.audioPlayer.position + const Duration(seconds: 1));
          },
          child: const Icon(Icons.fast_forward_rounded, size: 40),
        ),
      ],
    );
  }
}
