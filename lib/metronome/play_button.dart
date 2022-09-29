import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

class PlayButton extends StatelessWidget {
  /// Play / pause button to start or stop the [Metronome].
  const PlayButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Metronome.isRunningNotifier,
      builder: (context, bool isRunning, child) {
        return TextButton(
          onPressed: () {
            if (isRunning) {
              Metronome.stop();
            } else {
              Metronome.start();
            }
          },
          child: Icon(
            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 75,
          ),
        );
      },
    );
  }
}
