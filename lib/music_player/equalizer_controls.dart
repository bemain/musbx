import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/music_player.dart';

class EqualizerControls extends StatelessWidget {
  EqualizerControls({super.key});

  static List<AndroidEqualizerBand>? defaultBands;

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    AndroidEqualizerParameters? parameters;

    musicPlayer.equalizer.parameters.then(
      (value) {
        parameters = value;
        defaultBands ??= value.bands;

        musicPlayer.equalizer.setEnabled(true);
      },
    );

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
                    for (var band in parameters!.bands) {
                      band.setGain(
                          defaultBands![parameters!.bands.indexOf(band)].gain);
                    }
                  }),
                  icon: const Icon(Icons.refresh_rounded),
                )
              ],
            ),
            buildEqualizerSliders(parameters: parameters),
          ],
        );
      },
    );
  }

  Widget buildEqualizerSliders({AndroidEqualizerParameters? parameters}) {
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
                            onChanged:
                                (parameters == null) ? null : band?.setGain,
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
