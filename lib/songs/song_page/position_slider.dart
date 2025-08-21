import 'package:flutter/material.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/song_page/highlighted_section_slider_track_shape.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';
import 'package:musbx/utils/loading.dart';

class PositionSlider extends StatelessWidget {
  /// Slider for seeking a position in the current song.
  ///
  /// Includes labels displaying the current position and duration of the current song.
  /// If looping is enabled, highlights the section of the slider being looped.
  const PositionSlider({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    PositionSliderStyle style = Theme.of(
      context,
    ).extension<PositionSliderStyle>()!;

    if (Songs.player == null) {
      return ShimmerLoading(
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: const SizedBox(
                  height: 4,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final SongPlayer player = Songs.player!;

    return ValueListenableBuilder(
      valueListenable: player.positionNotifier,
      builder: (context, position, child) {
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
                trackShape: enabled
                    ? _buildSliderTrackShape(context, enabled)
                    : null,
              ),
              child: Slider(
                activeColor: enabled ? style.activeTrackColor : null,
                inactiveColor: enabled ? style.inactiveTrackColor : null,
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
                max: player.duration.inMilliseconds.roundToDouble(),
                value: position.inMilliseconds
                    .clamp(
                      enabled ? player.loop.start.inMilliseconds : 0,
                      enabled
                          ? player.loop.end.inMilliseconds
                          : player.duration.inMilliseconds,
                    )
                    .roundToDouble(),
                onChangeStart: (value) {
                  wasPlayingBeforeChange = player.isPlaying;
                  player.pause();
                },
                onChanged: (value) {
                  player.position = Duration(milliseconds: value.round());
                },
                onChangeEnd: (value) {
                  player.seek(Duration(milliseconds: value.round()));
                  if (wasPlayingBeforeChange) player.resume();
                },
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: _buildDurationText(context, player.duration),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Whether the player was playing before the user began changing the position.
  static bool wasPlayingBeforeChange = false;

  Widget _buildDurationText(BuildContext context, Duration duration) {
    return Text(
      durationString(duration),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  SliderTrackShape _buildSliderTrackShape(
    BuildContext context,
    bool loopEnabled,
  ) {
    if (Songs.player == null) {
      return RoundedRectSliderTrackShape();
    }

    final SongPlayer player = Songs.player!;

    PositionSliderStyle style = Theme.of(
      context,
    ).extension<PositionSliderStyle>()!;

    return HighlightedSectionSliderTrackShape(
      highlightStart:
          player.loop.start.inMilliseconds / player.duration.inMilliseconds,
      highlightEnd:
          player.loop.end.inMilliseconds / player.duration.inMilliseconds,
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
  return RegExp(
        r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$',
      ).firstMatch("$duration")?.group(1) ??
      "$duration";
}
