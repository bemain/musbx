import 'package:flutter/material.dart';
import 'package:musbx/music_player/loop_card/loop_slider.dart';
import 'package:musbx/music_player/loop_card/looper.dart';
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
              builder: (context, loopEnabled, _) => Switch(
                value: loopEnabled,
                onChanged: musicPlayer.nullIfNoSongElse(
                  (value) => musicPlayer.looper.enabled = value,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              "Loop",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: buildResetButton(),
          ),
        ],
      ),
      LoopSlider(),
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
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}
