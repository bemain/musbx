import 'package:flutter/material.dart';
import 'package:musbx/music_player/analyzer/chords_display.dart';
import 'package:musbx/music_player/analyzer/waveform_widget.dart';
import 'package:musbx/music_player/music_player.dart';

class AnalyzerCard extends StatelessWidget {
  AnalyzerCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  /// Whether the MusicPlayer was playing before the user began dragging.
  static bool wasPlayingBeforeChange = false;

  /// The duration shown before the user began zooming.
  static Duration durationShownBeforeChange = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          wasPlayingBeforeChange = musicPlayer.isPlaying;
          musicPlayer.pause();
        },
        onHorizontalDragUpdate: musicPlayer.nullIfNoSongElse((details) {
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
