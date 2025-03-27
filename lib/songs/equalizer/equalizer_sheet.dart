import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/equalizer/equalizer_sliders.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';

class EqualizerSheet extends StatelessWidget {
  const EqualizerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final SongPlayer player = Songs.player!;

    return ValueListenableBuilder(
      valueListenable: player.equalizer.bandsNotifier,
      builder: (context, bands, child) {
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      iconSize: 20,
                      onPressed: player.equalizer.resetGain,
                      icon: const Icon(Symbols.refresh),
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
