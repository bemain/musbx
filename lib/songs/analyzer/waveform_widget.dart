import 'package:flutter/material.dart';
import 'package:musbx/songs/analyzer/waveform_painter.dart';
import 'package:musbx/songs/player/music_player.dart';

class WaveformWidget extends StatelessWidget {
  WaveformWidget({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    if (musicPlayer.isLoading || musicPlayer.state == MusicPlayerState.idle) {
      return const SizedBox(); // TODO: Show dummy waveform when no song
    }

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
              final Color onSurface = Theme.of(context).colorScheme.onSurface;

              return CustomPaint(
                painter: WaveformPainter(
                  waveform: waveform,
                  position: position,
                  duration: durationShown,
                  activeColor: musicPlayer.isLoading
                      ? onSurface.withAlpha(0x61)
                      : Theme.of(context).colorScheme.primary,
                  inactiveColor: musicPlayer.isLoading
                      ? onSurface.withAlpha(0x1f)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                size: const Size(double.infinity, 64.0),
              );
            },
          ),
        );
      },
    );
  }
}
