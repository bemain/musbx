import 'package:flutter/material.dart';
import 'package:musbx/songs/equalizer/equalizer.dart';
import 'package:musbx/songs/equalizer/equalizer_overlay.dart';
import 'package:musbx/songs/equalizer/inactive_slider_track_shape.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';

class EqualizerSliders extends StatelessWidget {
  /// A widget used to control the gain on Equalizer's bands.
  const EqualizerSliders({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final SongPlayer player = Songs.player!;
    final EqualizerComponent equalizer = player.equalizer;

    return RepaintBoundary(
      child: CustomPaint(
        painter: EqualizerOverlayPainter(
          bands: equalizer.bands,
          lineColor: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withAlpha(0x61),
          fillColor:
              enabled ? Theme.of(context).colorScheme.inversePrimary : null,
        ),
        child: SliderTheme(
          data: Theme.of(context).sliderTheme.copyWith(
                trackShape: InactiveSliderTrackShape(),
              ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var band in equalizer.bands)
                buildSlider(band, enabled: enabled),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a [Slider] for controlling the gain on [band].
  Widget buildSlider(EqualizerBand band, {bool enabled = true}) {
    return ValueListenableBuilder(
      valueListenable: band.gainNotifier,
      builder: (context, value, child) {
        return RotatedBox(
          quarterTurns: -1,
          child: Slider(
            min: EqualizerBand.minGain,
            max: EqualizerBand.maxGain,
            value: band.gain,
            onChanged: !enabled ? null : (value) => band.gain = value,
          ),
        );
      },
    );
  }
}
