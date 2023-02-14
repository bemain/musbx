import 'package:flutter/material.dart';
import 'package:musbx/music_player/equalizer/equalizer_sliders.dart';
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
                      musicPlayer.equalizer.resetGain();
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ],
            ),
            EqualizerSliders(),
            Stack(
              alignment: Alignment.center,
              children: const [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Bass"),
                ),
                Text("Mid-range"),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text("Treble"),
                ),
              ],
            ),
          ]);
        },
      ),
    );
  }
}
