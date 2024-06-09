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
          return const CircularProgressIndicator();
        }

        return ValueListenableBuilder(
          valueListenable: musicPlayer.analyzer.durationShownNotifier,
          builder: (context, duraionShown, child) => ValueListenableBuilder(
            valueListenable: musicPlayer.positionNotifier,
            builder: (context, position, child) {
              return CustomPaint(
                painter: WaveformPainter(
                  waveform: waveform,
                  start: position - duraionShown * 0.5,
                  duration: duraionShown,
                  color: Theme.of(context).colorScheme.primary,
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
