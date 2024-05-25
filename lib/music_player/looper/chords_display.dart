import 'package:flutter/material.dart';
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
    return FutureBuilder(
      future: musicPlayer.analyzer.chordsProcess?.future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error_outline));
        }

        if (!snapshot.hasData) {
          return const Center(child: LinearProgressIndicator());
        }

        final Map<Duration, String> chords = snapshot.data!;
        return ValueListenableBuilder(
          valueListenable: musicPlayer.positionNotifier,
          builder: (context, position, child) {
            Duration minDuration = position - durationShown;
            Duration maxDuration = position + durationShown;
            List<MapEntry<Duration, String>> shownChords = chords.entries
                .where((e) => e.key > minDuration && e.key < maxDuration)
                .toList();
            return Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.circle, color: Colors.grey),
                ),
                ...shownChords.map((e) {
                  return Align(
                    alignment: Alignment(
                        (e.key - position).inMilliseconds /
                            (durationShown.inMilliseconds),
                        0),
                    child: Text(e.value),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
