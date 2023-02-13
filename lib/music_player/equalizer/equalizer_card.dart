import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/equalizer/equalizer_overlay.dart';
import 'package:musbx/music_player/music_player.dart';

class EqualizerCard extends StatelessWidget {
  EqualizerCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.equalizer.parametersNotifier,
      builder: (context, parameters, child) => ValueListenableBuilder(
        valueListenable: musicPlayer.equalizer.enabledNotifier,
        builder: (context, equalizerEnabled, child) {
          return Column(children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Switch(
                    value: equalizerEnabled,
                    onChanged: musicPlayer.nullIfNoSongElse(
                      (value) => musicPlayer.equalizer.enabled = value,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Center(
                    child: Text(
                      "Equalizer",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    iconSize: 20,
                    onPressed: musicPlayer.nullIfNoSongElse(() {
                      if (parameters != null) {
                        musicPlayer.equalizer.resetGain();
                      }
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ],
            ),
            buildEqualizerControls(
              context,
              equalizerEnabled,
              parameters: parameters,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                for (var band in parameters?.bands ?? List.filled(5, null))
                  Expanded(
                    child: Text('${band?.centerFrequency.round() ?? "--"} Hz'),
                  ),
              ],
            ),
          ]);
        },
      ),
    );
  }

  Widget buildEqualizerControls(
    BuildContext context,
    bool equalizerEnabled, {
    AndroidEqualizerParameters? parameters,
  }) {
    return CustomPaint(
      painter: EqualizerOverlayPainter(
        parameters: parameters,
        lineColor: Theme.of(context).colorScheme.primary,
        fillColor: Theme.of(context).colorScheme.primary,
      ),
      child: buildEqualizerSliders(context, equalizerEnabled,
          parameters: parameters),
    );
  }

  Widget buildEqualizerSliders(
    BuildContext context,
    bool equalizerEnabled, {
    AndroidEqualizerParameters? parameters,
  }) {
    return SizedBox(
      height: 250,
      child: SliderTheme(
        data: Theme.of(context).sliderTheme.copyWith(),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            for (var band in parameters?.bands ?? List.filled(5, null))
              Expanded(
                child: StreamBuilder<double>(
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}
