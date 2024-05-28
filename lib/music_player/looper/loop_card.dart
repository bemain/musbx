import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/analyzer/chords_display.dart';
import 'package:musbx/music_player/looper/loop_slider.dart';
import 'package:musbx/music_player/looper/looper.dart';
import 'package:musbx/music_player/music_player.dart';

class LoopCard extends StatelessWidget {
  LoopCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ValueListenableBuilder(
              valueListenable: musicPlayer.looper.enabledNotifier,
              builder: (context, enabled, _) => Switch(
                value: enabled,
                onChanged: musicPlayer.nullIfNoSongElse(
                  (value) => musicPlayer.looper.enabled = value,
                ),
              ),
            ),
          ),
          // Set the loopSection's start to position
          Align(
            alignment: const Alignment(-0.5, 0),
            child: IconButton(
              onPressed: musicPlayer.nullIfNoSongElse(() {
                musicPlayer.looper.section = LoopSection(
                  start: Duration(
                    milliseconds: min(
                      musicPlayer.looper.section.end.inMilliseconds - 1000,
                      musicPlayer.position.inMilliseconds,
                    ),
                  ),
                  end: musicPlayer.looper.section.end,
                );
              }),
              icon: const Icon(Icons.arrow_circle_right_outlined),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Center(
              child: Text(
                "Loop",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          // Set the loopSection's end to position
          Align(
            alignment: const Alignment(0.5, 0),
            child: IconButton(
              onPressed: musicPlayer.nullIfNoSongElse(() {
                musicPlayer.looper.section = LoopSection(
                  start: musicPlayer.looper.section.start,
                  end: Duration(
                    milliseconds: max(
                      musicPlayer.position.inMilliseconds,
                      musicPlayer.looper.section.start.inMilliseconds + 1000,
                    ),
                  ),
                );
              }),
              icon: const Icon(Icons.arrow_circle_left_outlined),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: buildResetButton(),
          ),
        ],
      ),
      LoopSlider(),
      const ChordsDisplay(),
    ]);
  }

  Widget buildResetButton() {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.looper.sectionNotifier,
      builder: (context, loopSection, child) => IconButton(
        iconSize: 20,
        onPressed: (loopSection == LoopSection(end: musicPlayer.duration))
            ? null
            : () {
                musicPlayer.looper.section =
                    LoopSection(end: musicPlayer.duration);
              },
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}
