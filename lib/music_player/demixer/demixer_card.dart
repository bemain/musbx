import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer.dart';
import 'package:musbx/music_player/music_player.dart';

class DemixerCard extends StatefulWidget {
  const DemixerCard({super.key});

  @override
  State<StatefulWidget> createState() => DemixerCardState();
}

class DemixerCardState extends State<DemixerCard> {
  MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: musicPlayer.demixer.enabledNotifier,
        builder: (context, demixerEnabled, child) {
          return ValueListenableBuilder(
            valueListenable: musicPlayer.demixer.loadingStateNotifier,
            builder: (context, loadingState, child) {
              return Column(children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Switch(
                        value: demixerEnabled,
                        onChanged: musicPlayer.nullIfNoSongElse(
                          !musicPlayer.demixer.isLoaded
                              ? null
                              : (value) => musicPlayer.demixer.enabled = value,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          "Demixer",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        iconSize: 20,
                        onPressed: musicPlayer.nullIfNoSongElse(() {
                          // TODO: Implement reset
                        }),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ],
                ),
                (!musicPlayer.demixer.isLoaded)
                    ? buildLoading()
                    : buildSliders(),
              ]);
            },
          );
        });
  }

  Widget buildLoading() {
    return ValueListenableBuilder(
        valueListenable: musicPlayer.demixer.loadingProgressNotifier,
        builder: (context, progress, child) {
          return SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(),
                if (progress != null) Text("$progress%"),
              ],
            ),
          );
        });
  }

  Widget buildSliders() {
    return Column(
      children: musicPlayer.demixer.stems.map(buildVolumeSlider).toList(),
    );
  }

  Widget buildVolumeSlider(Stem stem) {
    return ValueListenableBuilder(
      valueListenable: stem.enabledNotifier,
      builder: (context, stemEnabled, child) => Row(
        children: [
          Checkbox(
            value: stemEnabled,
            onChanged: musicPlayer.nullIfNoSongElse(
              (!musicPlayer.demixer.enabled)
                  ? null
                  : (bool? value) {
                      if (value != null) stem.enabled = value;
                    },
            ),
          ),
          Text(stem.type.name),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: stem.volumeNotifier,
              builder: (context, volume, child) => Slider(
                value: volume,
                onChanged: musicPlayer.nullIfNoSongElse(
                  (!musicPlayer.demixer.enabled || !stemEnabled)
                      ? null
                      : (double value) => stem.volume = value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
