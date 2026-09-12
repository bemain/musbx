import 'package:flutter/material.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';

class LoopSlider extends StatelessWidget {
  /// Range slider for selecting the section to loop.
  LoopSlider({super.key});

  /// Whether the player was playing before the user began changing the position.
  static bool wasPlayingBeforeChange = false;

  /// The position that the player was at before the user began changing the loop section.
  static Duration positionBeforeChange = Duration.zero;

  final PlaybackRepository playback = PlaybackRepository.instance;

  @override
  Widget build(BuildContext context) {
    if (playback.song == null) return SizedBox(height: 24);

    PositionSliderStyle style = Theme.of(
      context,
    ).extension<PositionSliderStyle>()!;

    return SliderTheme(
      data: Theme.of(context).sliderTheme.copyWith(
        rangeThumbShape: LoopSectionThumbShape(
          style: style,
          color: Theme.of(context).colorScheme.primary,
          disabledColor: Theme.of(context).colorScheme.primary,
        ),
        rangeTrackShape: LoopSliderTrackShape(
          style: style,
          outlineColor: Theme.of(context).colorScheme.primary,
          disabledOutlineColor: Theme.of(context).colorScheme.primary,
        ),
        valueIndicatorColor: Theme.of(context).colorScheme.primary,
        valueIndicatorStrokeColor: Colors.transparent,
      ),
      child: RangeSlider(
        padding: EdgeInsets.symmetric(horizontal: 20),
        labels: RangeLabels(
          playback.loopSection.start.toString().substring(2, 10),
          playback.loopSection.end.toString().substring(2, 10),
        ),
        min: 0,
        max: playback.duration?.inMilliseconds.toDouble() ?? 1.0,
        values: RangeValues(
          playback.loopSection.start?.inMilliseconds.toDouble() ?? 0,
          playback.loopSection.end?.inMilliseconds.toDouble() ?? 1.0,
        ),
        onChangeStart: (value) {
          positionBeforeChange = playback.position;
          wasPlayingBeforeChange = playback.isPlaying;
          playback.pause();
        },
        onChanged: (values) {
          final Duration? previousStart = playback.loopSection.start;
          final Duration? previousEnd = playback.loopSection.end;

          final start = Duration(milliseconds: values.start.toInt());
          final end = Duration(milliseconds: values.end.toInt());

          // Update section
          playback.setLoopSection(start: start, end: end);

          if (previousStart != start) {
            // The start value changed
            playback.position = start;
          }
          if (previousEnd != end) {
            // The end value changed
            playback.position = end;
          }
        },
        onChangeEnd: (value) {
          playback.seek(positionBeforeChange);
          if (wasPlayingBeforeChange) playback.resume();
        },
      ),
    );
  }
}

class LoopSliderTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  const LoopSliderTrackShape({
    required this.style,
    this.height = 24,
    this.outlineWidth = 1.0,
    this.outlineColor = Colors.black,
    this.disabledOutlineColor = Colors.grey,
  });

  final double height;
  final double outlineWidth;

  final PositionSliderStyle style;
  final Color outlineColor;
  final Color disabledOutlineColor;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.rangeThumbShape != null);

    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    // Assign the track segment paints, which are left: active, right: inactive,
    // but reversed for right to left text.
    final ColorTween outlineColorTween = ColorTween(
      begin: disabledOutlineColor,
      end: outlineColor,
    );

    final Paint outlinePaint = Paint()
      ..color = outlineColorTween.evaluate(enableAnimation)!;

    final (
      Offset leftThumbOffset,
      Offset rightThumbOffset,
    ) = switch (textDirection) {
      TextDirection.ltr => (startThumbCenter, endThumbCenter),
      TextDirection.rtl => (endThumbCenter, startThumbCenter),
    };
    final Size thumbSize = sliderTheme.rangeThumbShape!.getPreferredSize(
      isEnabled,
      isDiscrete,
    );
    final double thumbRadius = thumbSize.width / 2;
    assert(thumbRadius > 0);

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Draw loop section overlay
    context.canvas.drawRect(
      Rect.fromLTRB(
        leftThumbOffset.dx,
        trackRect.center.dy - height / 2,
        rightThumbOffset.dx,
        trackRect.center.dy + height / 2,
      ),
      Paint()..color = sliderTheme.overlayColor!,
    );

    // Draw border
    context.canvas.drawRect(
      Rect.fromLTRB(
        leftThumbOffset.dx,
        trackRect.center.dy + height / 2,
        rightThumbOffset.dx,
        trackRect.center.dy + height / 2 - outlineWidth,
      ),
      outlinePaint,
    );
    context.canvas.drawRect(
      Rect.fromLTRB(
        leftThumbOffset.dx,
        trackRect.center.dy - height / 2 + outlineWidth,
        rightThumbOffset.dx,
        trackRect.center.dy - height / 2,
      ),
      outlinePaint,
    );
  }
}

class LoopSectionThumbShape extends RangeSliderThumbShape {
  const LoopSectionThumbShape({
    required this.style,
    this.size = const Size(10, 24),
    this.radius = const Radius.circular(4),
    this.color = Colors.black,
    this.disabledColor = Colors.grey,
  });

  final Size size;
  final Radius radius;

  final PositionSliderStyle style;
  final Color color;
  final Color disabledColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return size;
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required SliderThemeData sliderTheme,
    bool? isDiscrete,
    bool? isEnabled,
    bool? isOnTop,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;
    final ColorTween colorTween = ColorTween(
      begin: disabledColor,
      end: this.color,
    );
    final Color color = colorTween.evaluate(enableAnimation)!;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: center,
          width: size.width,
          height: size.height,
        ),
        topRight: thumb == Thumb.end ? radius : Radius.zero,
        bottomRight: thumb == Thumb.end ? radius : Radius.zero,
        topLeft: thumb == Thumb.start ? radius : Radius.zero,
        bottomLeft: thumb == Thumb.start ? radius : Radius.zero,
      ),
      Paint()..color = color,
    );
    canvas.drawLine(
      center + Offset(0, size.height / 4),
      center - Offset(0, size.height / 4),
      Paint()
        ..color = sliderTheme.activeTickMarkColor!
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }
}
