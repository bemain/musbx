import 'package:flutter/material.dart';
import 'package:musbx/songs/analyzer/chords_display.dart';
import 'package:musbx/songs/analyzer/waveform_widget.dart';
import 'package:musbx/songs/loop/loop_slider.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/flat_card.dart';

class AnalyzerCard extends StatelessWidget {
  AnalyzerCard({super.key, this.scaleSpeed = 1 / 256});

  final SongPlayer player = Songs.player!;

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
        durationShownBeforeChange = player.analyzer.durationShown;
        wasPlayingBeforeChange = player.isPlaying;
        player.pause();
      },
      onScaleUpdate: (details) {
        // Seek
        final double dx = details.focalPointDelta.dx;
        player.position -= player.analyzer.durationShown * dx * scaleSpeed;

        // Zoom
        player.analyzer.durationShown =
            durationShownBeforeChange * (1 / details.scale);
      },
      onScaleEnd: (_) {
        player.seek(player.position);
        if (wasPlayingBeforeChange) player.resume();
      },
      child: FlatCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const ChordsDisplay(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: WaveformWidget(),
              ),
            ),
            LoopSlider(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
