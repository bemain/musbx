import 'package:flutter/material.dart';
import 'package:musbx/music_player/analyzer/waveform_painter.dart';
import 'package:musbx/music_player/music_player.dart';

class WaveformWidget extends StatelessWidget {
  WaveformWidget({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.analyzer.waveformNotifier,
      builder: (context, waveform, child) {
        if (waveform == null) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text("Analyzing..."),
            ],
          );
        }

        return ValueListenableBuilder(
          valueListenable: musicPlayer.analyzer.durationShownNotifier,
          builder: (context, durationShown, child) => ValueListenableBuilder(
            valueListenable: musicPlayer.positionNotifier,
            builder: (context, position, child) {
              final Color surfaceColor =
                  Theme.of(context).colorScheme.onSurface;

              return CustomPaint(
                painter: WaveformPainter(
                  waveform: waveform,
                  position: position,
                  duration: durationShown,
                  activeColor: musicPlayer.isLoading
                      ? surfaceColor.withOpacity(0.38)
                      : Theme.of(context).colorScheme.primary,
                  inactiveColor: musicPlayer.isLoading
                      ? surfaceColor.withOpacity(0.12)
                      : Theme.of(context).colorScheme.surfaceVariant,
                ),
                size: const Size(double.infinity, 100.0),
              );
            },
          ),
        );
      },
    );
  }
}
