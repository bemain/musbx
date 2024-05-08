import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/widgets.dart';

class PlayButton extends StatelessWidget {
  /// Play / pause button to start or stop the [Metronome].
  const PlayButton({Key? key, this.size}) : super(key: key);

  final double? size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Metronome.instance.isPlayingNotifier,
      builder: (context, bool isRunning, child) {
        final IconData icon =
            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded;

        return IconButton(
          onPressed: () {
            if (isRunning) {
              Metronome.instance.pause();
            } else {
              Metronome.instance.play();
            }
          },
          color: Theme.of(context).colorScheme.primary,
          icon: size == null
              ? ExpandedIcon(icon)
              : Icon(
                  icon,
                  size: size,
                ),
        );
      },
    );
  }
}
