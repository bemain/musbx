import 'package:flutter/material.dart';
import 'package:musbx/music_player/analyzer/chords_display.dart';
import 'package:musbx/music_player/analyzer/waveform_widget.dart';
import 'package:musbx/music_player/looper/loop_slider.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/page/flat_card.dart';

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
    return GestureDetector(
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
        musicPlayer.analyzer.durationShown =
            durationShownBeforeChange * (1 / details.scale);
      },
      onScaleEnd: (_) {
        if (wasPlayingBeforeChange) musicPlayer.play();
      },
      child: FlatCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const ChordsDisplay(),
            Expanded(child: WaveformWidget()),
            LoopSlider(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
