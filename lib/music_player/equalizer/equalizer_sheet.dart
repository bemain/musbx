import 'package:flutter/material.dart';
import 'package:musbx/music_player/equalizer/equalizer_sliders.dart';
import 'package:musbx/music_player/music_player.dart';

class EqualizerSheet extends StatelessWidget {
  EqualizerSheet({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.equalizer.parametersNotifier,
      builder: (context, parameters, child) {
        return SizedBox(
          height: 280,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Center(
                      child: Text(
                        "Equalizer",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      iconSize: 20,
                      onPressed: musicPlayer
                          .nullIfNoSongElse(musicPlayer.equalizer.resetGain),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: EqualizerSliders(),
            ),
            const SizedBox(height: 12),
            DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.labelMedium,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Stack(
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
              ),
            ),
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }
}
