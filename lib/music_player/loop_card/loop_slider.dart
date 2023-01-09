import 'package:flutter/material.dart';
import 'package:musbx/music_player/loop_card/looper.dart';
import 'package:musbx/music_player/music_player.dart';

class LoopSlider extends StatelessWidget {
  /// Range slider for selecting the section to loop.
  LoopSlider({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (_, duration, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.looper.enabledNotifier,
        builder: (_, loopEnabled, __) => ValueListenableBuilder(
          valueListenable: musicPlayer.looper.sectionNotifier,
          builder: (context, loopSection, _) {
            return RangeSlider(
              labels: RangeLabels(
                loopSection.start.toString().substring(2, 10),
                loopSection.end.toString().substring(2, 10),
              ),
              min: 0,
              max: duration.inMilliseconds.toDouble(),
              values: RangeValues(
                loopSection.start.inMilliseconds.toDouble(),
                loopSection.end.inMilliseconds.toDouble(),
              ),
              onChanged: !loopEnabled
                  ? null
                  : musicPlayer.nullIfNoSongElse((RangeValues values) {
                      musicPlayer.looper.section = LoopSection(
                        start: Duration(milliseconds: values.start.toInt()),
                        end: Duration(milliseconds: values.end.toInt()),
                      );
                    }),
            );
          },
        ),
      ),
    );
  }
}
