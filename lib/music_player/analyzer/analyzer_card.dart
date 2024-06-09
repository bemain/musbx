import 'package:flutter/material.dart';
import 'package:musbx/music_player/analyzer/chords_display.dart';
import 'package:musbx/music_player/analyzer/waveform_widget.dart';
import 'package:musbx/music_player/music_player.dart';

class AnalyzerCard extends StatelessWidget {
  AnalyzerCard({super.key, this.scaleSpeed = 1 / 256});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  /// Whether the MusicPlayer was playing before the user began dragging.
  static bool wasPlayingBeforeChange = false;

  /// The duration shown before the user began zooming.
  static Duration durationShownBeforeChange = Duration.zero;

  /// The speed at which the widget scales.
  final double scaleSpeed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: GestureDetector(
        onScaleStart: (_) {
          durationShownBeforeChange = musicPlayer.analyzer.durationShown;
          wasPlayingBeforeChange = musicPlayer.isPlaying;
          musicPlayer.pause();
        },
        onScaleUpdate: (details) {
          // Seek
          final double dx = details.focalPointDelta.dx;
          musicPlayer.seek(musicPlayer.position -
              musicPlayer.analyzer.durationShown * dx * scaleSpeed);

          // Zoom
          musicPlayer.analyzer.durationShownNotifier.value =
              durationShownBeforeChange * (1 / details.scale);
        },
        onScaleEnd: (_) {
          if (wasPlayingBeforeChange) musicPlayer.play();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const ChordsDisplay(),
            Expanded(child: WaveformWidget()),
          ],
        ),
      ),
    );
  }
}
