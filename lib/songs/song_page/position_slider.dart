import 'package:flutter/material.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/songs/loop/loop_slider.dart';
import 'package:musbx/songs/song_page/highlighted_section_slider_track_shape.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';
import 'package:musbx/widgets/widgets.dart';

class PositionSlider extends StatelessWidget {
  /// Slider for seeking a position in the current song.
  ///
  /// Includes labels displaying the current position and duration of the current song.
  /// If looping is enabled, highlights the section of the slider being looped.
  PositionSlider({super.key, this.enabled = true});

  final bool enabled;

  final PlaybackRepository playback = PlaybackRepository.instance;

  @override
  Widget build(BuildContext context) {
    if (playback.song == null) {
      return Column(
        children: [
          SizedBox(height: 24),
          SliderPlaceholder(trackHeight: 8),
        ],
      );
    }

    return ListenableBuilder(
      listenable: playback.positionNotifier,
      builder: (context, child) {
        return SizedBox(
          height: 48 + 24,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 48,
                  child: _buildSlider(context),
                ),
              ),

              Align(
                alignment: Alignment.bottomLeft,
                child: _buildDurationText(context, playback.position),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: playback.duration == null
                    ? null
                    : _buildDurationText(context, playback.duration!),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 24,
                  child: LoopSlider(),
                ),
              ),
            ],
          ),
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

  Widget _buildSlider(BuildContext context) {
    PositionSliderStyle style = Theme.of(
      context,
    ).extension<PositionSliderStyle>()!;

    return SliderTheme(
      data: Theme.of(context).sliderTheme.copyWith(
        trackHeight: 8,
        trackShape: enabled ? _buildSliderTrackShape(context, enabled) : null,
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
        max: playback.duration?.inMilliseconds.roundToDouble() ?? 1.0,
        value: playback.position.inMilliseconds
            .clamp(
              enabled ? playback.loopSection.start?.inMilliseconds ?? 0 : 0,
              (enabled ? playback.loopSection.end?.inMilliseconds : null) ??
                  (playback.duration?.inMilliseconds ?? 1.0),
            )
            .roundToDouble(),
        onChangeStart: (value) {
          wasPlayingBeforeChange = playback.isPlaying;
          playback.pause();
        },
        onChanged: (value) {
          playback.position = Duration(milliseconds: value.round());
        },
        onChangeEnd: (value) {
          playback.seek(Duration(milliseconds: value.round()));
          if (wasPlayingBeforeChange) playback.resume();
        },
      ),
    );
  }

  SliderTrackShape _buildSliderTrackShape(
    BuildContext context,
    bool loopEnabled,
  ) {
    if (playback.song == null) {
      return RoundedRectSliderTrackShape();
    }

    PositionSliderStyle style = Theme.of(
      context,
    ).extension<PositionSliderStyle>()!;

    return HighlightedSectionSliderTrackShape(
      highlightStart:
          (playback.loopSection.start?.inMilliseconds ?? 0) /
          (playback.duration?.inMilliseconds ?? 1.0),
      highlightEnd:
          (playback.loopSection.end?.inMilliseconds ?? 0) /
          (playback.duration?.inMilliseconds ?? 1.0),
      nonHighlightColor: style.nonLoopedTrackColor,
      disabledNonHighlightColor: style.disabledNonLoopedTrackColor,
    );
  }
}

String durationString(Duration duration) {
  return RegExp(
        r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$',
      ).firstMatch("$duration")?.group(1) ??
      "$duration";
}
