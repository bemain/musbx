import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

class PlayButton extends StatelessWidget {
  /// Play / pause button to start or stop the [Metronome].
  const PlayButton({Key? key, this.size = 75}) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Metronome.instance.isRunningNotifier,
      builder: (context, bool isRunning, child) {
        return TextButton(
          onPressed: () {
            if (isRunning) {
              Metronome.instance.stop();
            } else {
              Metronome.instance.start();
            }
          },
          child: Icon(
            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: size,
          ),
        );
      },
    );
  }
}
