import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/equalizer/equalizer_overlay.dart';
import 'package:musbx/music_player/equalizer/inactive_slider_track_shape.dart';
import 'package:musbx/music_player/music_player.dart';

class EqualizerSliders extends StatelessWidget {
  /// A widget used to control the gain on Equalizer's bands.
  EqualizerSliders({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.equalizer.parametersNotifier,
      builder: (context, parameters, child) => ValueListenableBuilder(
        valueListenable: musicPlayer.equalizer.enabledNotifier,
        builder: (context, equalizerEnabled, child) {
          return CustomPaint(
            painter: EqualizerOverlayPainter(
              parameters: parameters,
              lineColor: Theme.of(context).colorScheme.primary,
              fillColor: Theme.of(context).colorScheme.primary,
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
                    for (var band in parameters?.bands ?? List.filled(5, null))
                      Expanded(
                          child: buildSlider(
                        parameters: parameters,
                        band: band,
                        equalizerEnabled: equalizerEnabled,
                      )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build a [Slider] for controlling the gain on [band].
  Widget buildSlider({
    AndroidEqualizerParameters? parameters,
    AndroidEqualizerBand? band,
    required bool equalizerEnabled,
  }) {
    return StreamBuilder<double>(
      stream: band?.gainStream,
      builder: (context, snapshot) {
        return RotatedBox(
          quarterTurns: -1,
          child: Slider(
            min: parameters?.minDecibels ?? 0,
            max: parameters?.maxDecibels ?? 1,
            value: band?.gain ?? 0.5,
            onChanged: (!equalizerEnabled)
                ? null
                : (parameters == null)
                    ? null
                    : band?.setGain,
          ),
        );
      },
    );
  }
}
