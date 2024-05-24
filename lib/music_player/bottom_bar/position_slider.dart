import 'package:flutter/material.dart';
import 'package:musbx/music_player/looper/looper.dart';
import 'package:musbx/music_player/bottom_bar/highlighted_section_slider_track_shape.dart';
import 'package:musbx/music_player/music_player.dart';

class PositionSlider extends StatelessWidget {
  /// Slider for seeking a position in the current song.
  ///
  /// Includes labels displaying the current position and duration of the current song.
  /// If looping is enabled, highlights the section of the slider being looped.
  PositionSlider({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (_, duration, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.looper.enabledNotifier,
        builder: (_, loopEnabled, __) => ValueListenableBuilder(
          valueListenable: musicPlayer.looper.sectionNotifier,
          builder: (_, loopSection, __) => ValueListenableBuilder(
            valueListenable: musicPlayer.positionNotifier,
            builder: (context, position, _) => _buildSlider(
              context,
              duration,
              position,
              loopEnabled,
              loopSection,
            ),
          ),
        ),
      ),
    );
  }

  /// Whether the MusicPlayer was playing before the user began changing the position.
  static bool wasPlayingBeforeChange = false;

  Widget _buildSlider(
    BuildContext context,
    Duration duration,
    Duration position,
    bool loopEnabled,
    LoopSection loopSection,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: _buildDurationText(context, position),
          ),
        ),
        SliderTheme(
          data: Theme.of(context).sliderTheme.copyWith(
              trackShape: !loopEnabled
                  ? null
                  : musicPlayer.nullIfNoSongElse(_buildSliderTrackShape(
                      context,
                      duration,
                      loopSection,
                    ))),
          child: Slider(
            activeColor: loopEnabled
                ? Theme.of(context).colorScheme.background.withOpacity(0.24)
                : null,
            inactiveColor: loopEnabled
                ? Theme.of(context).colorScheme.background.withOpacity(0.24)
                : null,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: MaterialStateProperty.resolveWith((states) {
              final colors = Theme.of(context).colorScheme;
              if (states.contains(MaterialState.dragged)) {
                return colors.primary.withOpacity(0.12);
              }
              if (states.contains(MaterialState.hovered)) {
                return colors.primary.withOpacity(0.08);
              }
              if (states.contains(MaterialState.focused)) {
                return colors.primary.withOpacity(0.12);
              }

              return Colors.transparent;
            }),
            min: 0,
            max: duration.inMilliseconds.roundToDouble(),
            value: position.inMilliseconds
                .clamp(
                  loopEnabled ? loopSection.start.inMilliseconds : 0,
                  loopEnabled
                      ? loopSection.end.inMilliseconds
                      : duration.inMilliseconds,
                )
                .roundToDouble(),
            onChangeStart: (_) {
              wasPlayingBeforeChange = musicPlayer.isPlaying;
              musicPlayer.pause();
            },
            onChanged: musicPlayer.nullIfNoSongElse((double value) {
              musicPlayer.seek(Duration(milliseconds: value.round()));
            }),
            onChangeEnd: (_) {
              if (wasPlayingBeforeChange) musicPlayer.play();
            },
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomRight,
            child: _buildDurationText(context, duration),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationText(BuildContext context, Duration duration) {
    return Text(
      (musicPlayer.state != MusicPlayerState.ready)
          ? "-- : --"
          : durationString(duration),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  SliderTrackShape _buildSliderTrackShape(
    BuildContext context,
    Duration duration,
    LoopSection loopSection,
  ) {
    return HighlightedSectionSliderTrackShape(
      highlightStart:
          loopSection.start.inMilliseconds / duration.inMilliseconds,
      highlightEnd: loopSection.end.inMilliseconds / duration.inMilliseconds,
      activeHighlightColor: Theme.of(context).colorScheme.primary,
      inactiveHighlightColor:
          Theme.of(context).colorScheme.primary.withOpacity(0.24),
    );
  }
}

String durationString(Duration duration) {
  return RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
          .firstMatch("$duration")
          ?.group(1) ??
      "$duration";
}
