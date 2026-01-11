import 'package:flutter/material.dart';
import 'package:musbx/songs/analyzer/chords_display.dart';
import 'package:musbx/songs/analyzer/waveform_widget.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/flat_card.dart';

class WaveformCard extends StatelessWidget {
  const WaveformCard({
    super.key,
    this.scaleSpeed = 1 / 256,
    this.radius = const BorderRadius.all(Radius.circular(32)),
  });

  /// Whether the MusicPlayer was playing before the user began dragging.
  static bool wasPlayingBeforeChange = false;

  /// The duration shown before the user began zooming.
  static Duration durationShownBeforeChange = Duration.zero;

  /// The speed at which the widget scales.
  final double scaleSpeed;

  final BorderRadiusGeometry radius;

  @override
  Widget build(BuildContext context) {
    final SongPlayer? player = Songs.player;

    return GestureDetector(
      onScaleStart: (_) {
        if (player != null) {
          durationShownBeforeChange = player.analyzer.durationShown;
          wasPlayingBeforeChange = player.isPlaying;
        }
        player?.pause();
      },
      onScaleUpdate: (details) {
        // Seek
        final double dx = details.focalPointDelta.dx;
        player?.position -= player.analyzer.durationShown * dx * scaleSpeed;

        // Zoom
        player?.analyzer.durationShown =
            durationShownBeforeChange * (1 / details.scale);
      },
      onScaleEnd: (_) {
        player?.seek(player.position);
        if (wasPlayingBeforeChange) player?.resume();
      },
      child: FlatCard(
        radius: radius,
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
          ],
        ),
      ),
    );
  }
}
