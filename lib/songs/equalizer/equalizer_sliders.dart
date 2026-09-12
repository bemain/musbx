import 'package:flutter/material.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/songs/equalizer/equalizer_overlay.dart';
import 'package:musbx/songs/equalizer/inactive_slider_track_shape.dart';

class EqualizerSliders extends StatelessWidget {
  /// A widget used to control the gain on Equalizer's bands.
  EqualizerSliders({super.key, this.enabled = true});

  final bool enabled;

  final PlaybackRepository playback = PlaybackRepository.instance;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: EqualizerOverlayPainter(
          bands: playback.numEqualizerBands == null
              ? null
              : {
                  for (int i = 0; i < playback.numEqualizerBands!; i++)
                    i:
                        playback.getBandGain(i) ??
                        PlaybackRepository.equalizerDefaultGain,
                },
          lineColor: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withAlpha(0x61),
          fillColor: enabled
              ? Theme.of(context).colorScheme.inversePrimary
              : null,
        ),
        child: SliderTheme(
          data: Theme.of(context).sliderTheme.copyWith(
            year2023: true,
            trackShape: InactiveSliderTrackShape(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < playback.numEqualizerBands!; i++)
                buildSlider(i, enabled: enabled),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a [Slider] for controlling the gain on [band].
  Widget buildSlider(int band, {bool enabled = true}) {
    return RotatedBox(
      quarterTurns: -1,
      child: Slider(
        min: PlaybackRepository.equalizerMinGain,
        max: PlaybackRepository.equalizerMaxGain,
        value:
            playback.getBandGain(band) ??
            PlaybackRepository.equalizerDefaultGain,
        onChanged: !enabled
            ? null
            : (value) => playback.setBandGain(band, value),
      ),
    );
  }
}
