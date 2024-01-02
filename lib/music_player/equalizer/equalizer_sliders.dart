import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/demixer/stem.dart';
import 'package:musbx/music_player/equalizer/equalizer.dart';
import 'package:musbx/music_player/equalizer/equalizer_overlay.dart';
import 'package:musbx/music_player/equalizer/inactive_slider_track_shape.dart';
import 'package:musbx/music_player/music_player.dart';

class EqualizerSliders extends StatelessWidget {
  /// A widget used to control the gain on Equalizer's bands.
  EqualizerSliders({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;
  final Equalizer equalizer = MusicPlayer.instance.equalizer;

  @override
  Widget build(BuildContext context) {
    final bool enabled = equalizer.parameters != null &&
        equalizer.enabled &&
        !musicPlayer.isLoading &&
        musicPlayer.state != MusicPlayerState.idle;

    return RepaintBoundary(
      child: CustomPaint(
        painter: EqualizerOverlayPainter(
          parameters: equalizer.parameters,
          lineColor: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          fillColor:
              enabled ? Theme.of(context).colorScheme.inversePrimary : null,
        ),
        child: AspectRatio(
          aspectRatio: 16 / 11,
          child: SliderTheme(
            data: Theme.of(context).sliderTheme.copyWith(
                  trackShape: InactiveSliderTrackShape(),
                ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var band
                    in equalizer.parameters?.bands ?? List.filled(5, null))
                  buildSlider(band: band, enabled: enabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a [Slider] for controlling the gain on [band].
  Widget buildSlider({AndroidEqualizerBand? band, bool enabled = true}) {
    return StreamBuilder<double>(
      stream: band?.gainStream,
      builder: (context, snapshot) {
        return SizedBox(
          width: 28.0,
          child: RotatedBox(
            quarterTurns: -1,
            child: Slider(
              min: equalizer.parameters?.minDecibels ?? 0,
              max: equalizer.parameters?.maxDecibels ?? 1,
              value: band?.gain ?? Stem.defaultVolume,
              onChanged: !enabled ? null : band?.setGain,
            ),
          ),
        );
      },
    );
  }
}
