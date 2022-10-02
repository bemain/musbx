import 'package:flutter/material.dart';
import 'package:musbx/music_player/highlighted_section_slider_track_shape.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';

class PositionSlider extends StatelessWidget {
  const PositionSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (_, duration, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.loopEnabledNotifier,
        builder: (_, loopEnabled, __) => ValueListenableBuilder(
          valueListenable: musicPlayer.loopSectionNotifier,
          builder: (_, loopSection, __) => ValueListenableBuilder(
            valueListenable: musicPlayer.positionNotifier,
            builder: (context, position, _) {
              return Row(
                children: [
                  _buildDurationText(context, position),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                          thumbColor: (loopEnabled &&
                                  loopSection.start <= position &&
                                  position <= loopSection.end)
                              ? Colors.deepPurple
                              : null,
                          trackShape: (musicPlayer.songTitle == null ||
                                  !loopEnabled)
                              ? null
                              : _buildSliderTrackShape(duration!, loopSection)),
                      child: Slider(
                        min: 0,
                        max: duration?.inMilliseconds.roundToDouble() ?? 0,
                        value: position.inMilliseconds.roundToDouble(),
                        onChanged: (musicPlayer.songTitle == null)
                            ? null
                            : (double value) {
                                musicPlayer.seek(
                                    Duration(milliseconds: value.round()));
                              },
                      ),
                    ),
                  ),
                  _buildDurationText(context, duration),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDurationText(BuildContext context, Duration? duration) {
    return Text(
      (duration == null) ? "-- : --" : durationString(duration),
      style: Theme.of(context).textTheme.caption,
    );
  }

  SliderTrackShape _buildSliderTrackShape(
    Duration duration,
    LoopSection loopSection,
  ) {
    return HighlightedSectionSliderTrackShape(
      highlightStart:
          loopSection.start.inMilliseconds / duration.inMilliseconds,
      highlightEnd: loopSection.end.inMilliseconds / duration.inMilliseconds,
      activeHighlightColor: Colors.deepPurple,
      inactiveHighlightColor: Colors.purple.withAlpha(100),
    );
  }
}
