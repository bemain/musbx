import 'package:flutter/material.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';
import 'package:musbx/songs/looper/looper.dart';
import 'package:musbx/songs/song_page/highlighted_section_slider_track_shape.dart';
import 'package:musbx/songs/player/music_player.dart';

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
          builder: (_, loopSection, __) => StreamBuilder(
            stream: MusicPlayerNew.instance.createPositionStream(),
            builder: (context, snapshot) => _buildSlider(
              context,
              duration,
              snapshot.data ?? Duration.zero,
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
    PositionSliderStyle style =
        Theme.of(context).extension<PositionSliderStyle>()!;

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
                trackShape: musicPlayer.nullIfNoSongElse(_buildSliderTrackShape(
                  context,
                  duration,
                  loopEnabled,
                  loopSection,
                )),
              ),
          child: Slider(
            activeColor: loopEnabled ? style.activeTrackColor : null,
            inactiveColor: loopEnabled ? style.inactiveTrackColor : null,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              final colors = Theme.of(context).colorScheme;
              if (states.contains(WidgetState.dragged)) {
                return colors.primary.withAlpha(0x1a);
              }
              if (states.contains(WidgetState.hovered)) {
                return colors.primary.withAlpha(0x14);
              }
              if (states.contains(WidgetState.focused)) {
                return colors.primary.withAlpha(0x1a);
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
    bool loopEnabled,
    LoopSection loopSection,
  ) {
    PositionSliderStyle style =
        Theme.of(context).extension<PositionSliderStyle>()!;

    return HighlightedSectionSliderTrackShape(
      highlightStart:
          loopSection.start.inMilliseconds / duration.inMilliseconds,
      highlightEnd: loopSection.end.inMilliseconds / duration.inMilliseconds,
      activeHighlightColor: loopEnabled
          ? style.activeLoopedTrackColor
          : style.disabledActiveLoopedTrackColor,
      inactiveHighlightColor: loopEnabled
          ? style.inactiveLoopedTrackColor
          : style.disabledInactiveLoopedTrackColor,
    );
  }
}

String durationString(Duration duration) {
  return RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
          .firstMatch("$duration")
          ?.group(1) ??
      "$duration";
}
