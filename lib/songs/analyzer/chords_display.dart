import 'package:flutter/material.dart';
import 'package:musbx/model/chord.dart';
import 'package:musbx/songs/analyzer/chord_symbol.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';

class ChordsDisplay extends StatefulWidget {
  const ChordsDisplay({super.key});

  @override
  State<ChordsDisplay> createState() => _ChordsDisplayState();
}

class _ChordsDisplayState extends State<ChordsDisplay> {
  final SongPlayer player = Songs.player!;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.0,
      child: LayoutBuilder(
        builder: (context, constraints) => ValueListenableBuilder(
          valueListenable: player.analyzer.chordsNotifier,
          builder: (context, chords, child) {
            if (chords == null) return const SizedBox();

            return ValueListenableBuilder(
              valueListenable: player.analyzer.durationShownNotifier,
              builder: (context, durationShown, child) =>
                  ValueListenableBuilder(
                valueListenable: player.positionNotifier,
                builder: (context, position, child) {
                  Duration minDuration = player.position - durationShown * 0.5;
                  Duration maxDuration = player.position + durationShown * 0.5;
                  List<MapEntry<Duration, Chord?>> shownChords = chords.entries
                      .where((e) => e.key > minDuration && e.key < maxDuration)
                      .toList();

                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ...shownChords.map((e) {
                        final Chord? chord = e.value;
                        return Positioned(
                          left: ((e.key - player.position).inMilliseconds /
                                      (durationShown.inMilliseconds) +
                                  0.5) *
                              constraints.maxWidth,
                          child: chord == null
                              ? const SizedBox()
                              : ChordSymbol(
                                  chord: chord,
                                  color: e.key <= player.position
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                        );
                      }),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
