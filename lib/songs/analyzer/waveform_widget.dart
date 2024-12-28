import 'package:flutter/material.dart';
import 'package:musbx/songs/analyzer/waveform_painter.dart';
import 'package:musbx/songs/loop_style.dart';
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
              return CustomPaint(
                painter: WaveformPainter(
                  waveform: waveform,
                  position: position,
                  duration: durationShown,
                  style: Theme.of(context).extension<LoopStyle>()!,
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
