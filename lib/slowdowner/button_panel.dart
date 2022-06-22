import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/slowdowner.dart';

class ButtonPanel extends StatelessWidget {
  /// Panel including play/pause, forward and rewind buttons for controlling [Slowdowner].
  const ButtonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final Slowdowner slowdowner = Slowdowner.instance;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            slowdowner.seek(slowdowner.position - const Duration(seconds: 1));
          },
          onLongPress: () {
            slowdowner.seek(Duration.zero);
          },
          child: const Icon(Icons.fast_rewind_rounded, size: 40),
        ),
        StreamBuilder<bool>(
          stream: slowdowner.playingStream,
          initialData: false,
          builder: (context, snapshot) {
            bool isPlaying = snapshot.data!;
            return TextButton(
              onPressed: (() {
                if (isPlaying) {
                  slowdowner.pause();
                } else {
                  slowdowner.play();
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
            slowdowner.seek(slowdowner.position + const Duration(seconds: 1));
          },
          child: const Icon(Icons.fast_forward_rounded, size: 40),
        ),
      ],
    );
  }
}
