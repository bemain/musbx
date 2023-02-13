import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/equalizer/equalizer.dart';
import 'package:musbx/music_player/equalizer/equalizer_overlay.dart';
import 'package:musbx/music_player/equalizer/inactive_slider_track_shape.dart';
import 'package:musbx/music_player/music_player.dart';

class EqualizerSliders extends StatelessWidget {
  /// A widget used to control the gain on Equalizer's bands.
  EqualizerSliders({super.key});

  final Equalizer equalizer = MusicPlayer.instance.equalizer;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: EqualizerOverlayPainter(
        parameters: equalizer.parameters,
        lineColor: (equalizer.parameters != null && equalizer.enabled)
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
        fillEnabled:
            (equalizer.parameters != null && equalizer.enabled) ? true : false,
      ),
      child: SizedBox(
        height: 250,
        child: SliderTheme(
          data: Theme.of(context)
              .sliderTheme
              .copyWith(trackShape: InactiveSliderTrackShape()),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              for (var band
                  in equalizer.parameters?.bands ?? List.filled(5, null))
                Expanded(child: buildSlider(band: band)),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a [Slider] for controlling the gain on [band].
  Widget buildSlider({AndroidEqualizerBand? band}) {
    return StreamBuilder<double>(
      stream: band?.gainStream,
      builder: (context, snapshot) {
        return RotatedBox(
          quarterTurns: -1,
          child: Slider(
            min: equalizer.parameters?.minDecibels ?? 0,
            max: equalizer.parameters?.maxDecibels ?? 1,
            value: band?.gain ?? 0.5,
            onChanged: (!equalizer.enabled)
                ? null
                : (equalizer.parameters == null)
                    ? null
                    : band?.setGain,
          ),
        );
      },
    );
  }
}
