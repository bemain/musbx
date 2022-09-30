import 'package:flutter/material.dart';
import 'package:musbx/music_player/highlighted_section_slider_track_shape.dart';
import 'package:musbx/music_player/music_player.dart';

class PositionSlider extends StatelessWidget {
  const PositionSlider({super.key});

  final Duration repeatStart = const Duration(seconds: 30);
  final Duration repeatEnd = const Duration(seconds: 120);

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (context, duration, child) => ValueListenableBuilder(
        valueListenable: musicPlayer.positionNotifier,
        builder: (context, position, child) {
          return Row(
            children: [
              _buildDurationText(context, position),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                      thumbColor:
                          (repeatStart < position && position < repeatEnd)
                              ? Colors.deepPurple
                              : null,
                      trackShape: (musicPlayer.songTitle == null)
                          ? null
                          : _buildSliderTrackShape(duration!)),
                  child: Slider(
                    min: 0,
                    max: duration?.inMilliseconds.roundToDouble() ?? 0,
                    value: position.inMilliseconds.roundToDouble(),
                    onChanged: (musicPlayer.songTitle == null)
                        ? null
                        : (double value) {
                            musicPlayer
                                .seek(Duration(milliseconds: value.round()));
                          },
                  ),
                ),
              ),
              _buildDurationText(context, duration),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDurationText(BuildContext context, Duration? duration) {
    return Text(
      (duration == null)
          ? "-- : --"
          : RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                  .firstMatch("$duration")
                  ?.group(1) ??
              "$duration",
      style: Theme.of(context).textTheme.caption,
    );
  }

  SliderTrackShape _buildSliderTrackShape(Duration duration) {
    return HighlightedSectionSliderTrackShape(
      highlightStart: repeatStart.inMilliseconds / duration.inMilliseconds,
      highlightEnd: repeatEnd.inMilliseconds / duration.inMilliseconds,
      activeHighlightColor: Colors.deepPurple,
      inactiveHighlightColor: Colors.purple.withAlpha(100),
    );
  }
}
