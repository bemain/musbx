import 'package:flutter/material.dart';
import 'package:musbx/model/chord.dart';
import 'package:musbx/music_player/analyzer/chord_symbol.dart';
import 'package:musbx/music_player/music_player.dart';

class ChordsDisplay extends StatefulWidget {
  const ChordsDisplay({super.key});

  @override
  State<ChordsDisplay> createState() => _ChordsDisplayState();
}

class _ChordsDisplayState extends State<ChordsDisplay> {
  static const Duration durationShown = Duration(seconds: 5);

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ValueListenableBuilder(
        valueListenable: musicPlayer.analyzer.chordsNotifier,
        builder: (context, chords, child) {
          if (chords == null) {
            return const Center(child: LinearProgressIndicator());
          }

          return ValueListenableBuilder(
            valueListenable: musicPlayer.positionNotifier,
            builder: (context, position, child) {
              Duration minDuration = position - durationShown;
              Duration maxDuration = position + durationShown;
              List<MapEntry<Duration, Chord?>> shownChords = chords.entries
                  .where((e) => e.key > minDuration && e.key < maxDuration)
                  .toList();
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.circle, color: Colors.grey),
                  ),
                  ...shownChords.map((e) {
                    final Chord? chord = e.value;
                    return chord == null
                        ? const SizedBox()
                        : Positioned(
                            left: ((e.key - position).inMilliseconds /
                                        (durationShown.inMilliseconds * 2) +
                                    0.5) *
                                constraints.maxWidth,
                            child: ChordSymbol(chord: chord),
                          );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
