import 'package:flutter/material.dart';
import 'package:musbx/music_player/card_header.dart';
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
        builder: (context, enabled, child) {
          return Column(children: [
            CardHeader(
              title: "Equalizer",
              enabled: enabled,
              onEnabledChanged: (value) {
                musicPlayer.equalizer.enabled = value;
              },
              onResetPressed: musicPlayer.equalizer.resetGain,
            ),
            EqualizerSliders(),
            const Stack(
              alignment: Alignment.center,
              children: [
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
