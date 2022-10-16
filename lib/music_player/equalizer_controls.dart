import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';

class EqualizerControls extends StatelessWidget {
  const EqualizerControls({super.key});

  static List<AndroidEqualizerBand>? defaultBands;

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    musicPlayer.equalizer.setEnabled(true);

    return FutureBuilder<AndroidEqualizerParameters>(
      future: musicPlayer.equalizer.parameters,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorScreen(text: "Unable to get Equalizer parameters");
        }
        if (!snapshot.hasData) {
          return const LoadingScreen(text: "Getting Equalizer parameters...");
        }

        final AndroidEqualizerParameters parameters = snapshot.data!;
        defaultBands ??= parameters.bands;
        return Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StreamBuilder(
                stream: musicPlayer.equalizer.enabledStream,
                builder: (context, snapshot) => Switch(
                    value: snapshot.data ?? false,
                    onChanged: musicPlayer.nullIfNoSongElse(
                      musicPlayer.equalizer.setEnabled,
                    )),
              ),
              Text(
                "Equalizer",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                iconSize: 20,
                onPressed: () {
                  for (var band in parameters.bands) {
                    band.setGain(
                        defaultBands![parameters.bands.indexOf(band)].gain);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
              )
            ],
          ),
          SizedBox(
            height: 250,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                for (var band in parameters.bands)
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: StreamBuilder<double>(
                            stream: band.gainStream,
                            builder: (context, snapshot) {
                              return RotatedBox(
                                quarterTurns: -1,
                                child: Slider(
                                  min: parameters.minDecibels,
                                  max: parameters.maxDecibels,
                                  value: band.gain,
                                  onChanged: band.setGain,
                                ),
                              );
                            },
                          ),
                        ),
                        Text('${band.centerFrequency.round()} Hz'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ]);
      },
    );
  }
}
