import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';

class LoopSlider extends StatelessWidget {
  /// Range slider for selecting the section to loop.
  const LoopSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (_, duration, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.loopEnabledNotifier,
        builder: (_, loopEnabled, __) => ValueListenableBuilder(
          valueListenable: musicPlayer.loopSectionNotifier,
          builder: (context, loopSection, _) {
            return RangeSlider(
              labels: RangeLabels(
                durationString(loopSection.start),
                durationString(loopSection.end),
              ),
              min: 0,
              max: duration.inMilliseconds.toDouble(),
              values: RangeValues(
                loopSection.start.inMilliseconds.toDouble(),
                loopSection.end.inMilliseconds.toDouble(),
              ),
              onChanged: (musicPlayer.songTitle == null || !loopEnabled)
                  ? null
                  : (RangeValues values) {
                      musicPlayer.loopSection = LoopSection(
                        start: Duration(milliseconds: values.start.toInt()),
                        end: Duration(milliseconds: values.end.toInt()),
                      );
                    },
            );
          },
        ),
      ),
    );
  }
}
