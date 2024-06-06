import 'package:flutter/material.dart';
import 'package:musbx/music_player/analyzer/waveform_painter.dart';
import 'package:musbx/music_player/music_player.dart';

class WaveformWidget extends StatelessWidget {
  WaveformWidget({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  /// Whether the MusicPlayer was playing before the user began changing the position.
  static bool wasPlayingBeforeChange = false;
  static Duration durationShownBeforeChange = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.analyzer.waveformNotifier,
      builder: (context, waveform, child) {
        if (waveform == null) {
          return const CircularProgressIndicator();
        }

        return GestureDetector(
          onHorizontalDragStart: (_) {
            wasPlayingBeforeChange = musicPlayer.isPlaying;
            musicPlayer.pause();
          },
          onHorizontalDragUpdate: musicPlayer.nullIfNoSongElse((details) {
            // TODO: Remove stuttering when dragging
            if (details.delta.dx.abs() < 0.0) return;
            musicPlayer.seek(musicPlayer.position -
                musicPlayer.analyzer.durationShown * (details.delta.dx / 128));
          }),
          onHorizontalDragEnd: (_) {
            if (wasPlayingBeforeChange) musicPlayer.play();
          },
          onHorizontalDragCancel: () {
            if (wasPlayingBeforeChange) musicPlayer.play();
          },
          onScaleStart: (_) {
            durationShownBeforeChange = musicPlayer.analyzer.durationShown;
          },
          onScaleUpdate: (details) {
            musicPlayer.analyzer.durationShownNotifier.value =
                durationShownBeforeChange * (1 / details.scale);
          },
          child: ValueListenableBuilder(
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
          ),
        );
      },
    );
  }
}
