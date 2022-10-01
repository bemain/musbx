import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class LoopSlider extends StatelessWidget {
  /// Range slider for selecting the section to loop.
  const LoopSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (context, duration, child) {
        return ValueListenableBuilder(
          valueListenable: musicPlayer.loopSectionNotifier,
          builder: (context, loopSection, child) {
            return RangeSlider(
              min: 0,
              max: duration?.inMilliseconds.toDouble() ?? 1000,
              values: RangeValues(
                loopSection.start.inMilliseconds.toDouble(),
                loopSection.end.inMilliseconds.toDouble(),
              ),
              onChanged: (RangeValues values) {
                musicPlayer.loopSection = LoopSection(
                  start: Duration(milliseconds: values.start.toInt()),
                  end: Duration(milliseconds: values.end.toInt()),
                );
              },
            );
          },
        );
      },
    );
  }
}
