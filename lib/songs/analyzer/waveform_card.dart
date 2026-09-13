import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/songs/analyzer/chords_display.dart';
import 'package:musbx/songs/analyzer/waveform_widget.dart';
import 'package:musbx/widgets/flat_card.dart';

class WaveformCard extends StatelessWidget {
  static const Duration minDurationShown = Duration(seconds: 7);
  static const Duration maxDurationShown = Duration(seconds: 10);
  static const Duration defaultDurationShown = Duration(seconds: 8);

  WaveformCard({
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

  Duration get durationShown => durationShownNotifier.value;
  set durationShown(Duration value) => durationShownNotifier.value = value
      .clamp(minDurationShown, maxDurationShown);
  late final ValueNotifier<Duration> durationShownNotifier = ValueNotifier(
    defaultDurationShown,
  );

  final PlaybackRepository playback = PlaybackRepository.instance;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (_) {
        if (playback.song != null) {
          durationShownBeforeChange = durationShown;
          wasPlayingBeforeChange = playback.isPlaying;
        }
        playback.pause();
      },
      onScaleUpdate: (details) {
        // Seek
        final double dx = details.focalPointDelta.dx;
        playback.position -= durationShown * dx * scaleSpeed;

        // Zoom
        durationShown = durationShownBeforeChange * (1 / details.scale);
      },
      onScaleEnd: (_) {
        playback.seek(playback.position);
        if (wasPlayingBeforeChange) playback.resume();
      },
      child: FlatCard(
        radius: radius,
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: ValueListenableBuilder(
          valueListenable: durationShownNotifier,
          builder: (context, durationShown, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              ChordsDisplay(durationShown: durationShown),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: WaveformWidget(durationShown: durationShown),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
