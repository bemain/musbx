import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/music_player.dart';

class EqualizerControls extends StatelessWidget {
  EqualizerControls({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    AndroidEqualizerParameters? parameters;
    () async {
      await musicPlayer.equalizer.setEnabled(false);
      parameters = await musicPlayer.equalizer.parameters;
      resetGain(parameters!);
      await musicPlayer.equalizer.setEnabled(true);
    }();

    return ValueListenableBuilder(
      valueListenable: musicPlayer.equalizerEnabledNotifier,
      builder: (context, equalizerEnabled, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch(
                  value: equalizerEnabled,
                  onChanged: musicPlayer.nullIfNoSongElse(
                    musicPlayer.equalizer.setEnabled,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Equalizer",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  iconSize: 20,
                  onPressed: musicPlayer.nullIfNoSongElse(() {
                    if (parameters != null) resetGain(parameters!);
                  }),
                  icon: const Icon(Icons.refresh_rounded),
                )
              ],
            ),
            buildEqualizerSliders(equalizerEnabled, parameters: parameters),
          ],
        );
      },
    );
  }

  /// Reset the gain on all bands in [parameters]
  void resetGain(AndroidEqualizerParameters parameters) {
    for (var band in parameters.bands) {
      band.setGain((parameters.maxDecibels + parameters.minDecibels) / 2);
    }
  }

  Widget buildEqualizerSliders(
    bool equalizerEnabled, {
    AndroidEqualizerParameters? parameters,
  }) {
    return SizedBox(
      height: 250,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          for (var band in parameters?.bands ?? List.filled(5, null))
            Expanded(
              child: Column(
                children: [
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
                  Text('${band?.centerFrequency.round() ?? "--"} Hz'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
