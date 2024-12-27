import 'package:flutter/material.dart';
import 'package:musbx/songs/loop_style.dart';
import 'package:musbx/songs/looper/looper.dart';
import 'package:musbx/songs/player/music_player.dart';

class LoopSlider extends StatelessWidget {
  /// Range slider for selecting the section to loop.
  LoopSlider({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    bool wasPlayingBeforeChange = false;

    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (_, duration, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.looper.enabledNotifier,
        builder: (_, loopEnabled, __) => ValueListenableBuilder(
          valueListenable: musicPlayer.looper.sectionNotifier,
          builder: (context, loopSection, _) {
            LoopStyle style = Theme.of(context).extension<LoopStyle>()!;

            return SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                    rangeThumbShape: LoopSectionThumbShape(style: style),
                    rangeTrackShape: LoopSliderTrackShape(style: style),
                    valueIndicatorColor: Theme.of(context).colorScheme.primary,
                    valueIndicatorStrokeColor: Colors.transparent,
                  ),
              child: RangeSlider(
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
                onChangeStart: (value) {
                  wasPlayingBeforeChange = musicPlayer.isPlaying;
                  musicPlayer.pause();
                },
                onChangeEnd: (value) {
                  if (wasPlayingBeforeChange) musicPlayer.play();
                },
                onChanged: !loopEnabled
                    ? null
                    : musicPlayer.nullIfNoSongElse((RangeValues values) {
                        final LoopSection previous = musicPlayer.looper.section;

                        // Update section
                        musicPlayer.looper.section = LoopSection(
                          start: Duration(milliseconds: values.start.toInt()),
                          end: Duration(milliseconds: values.end.toInt()),
                        );

                        if (previous.start.inMilliseconds != values.start) {
                          // The start value changed
                          musicPlayer.seek(
                            Duration(milliseconds: values.start.toInt()),
                          );
                        } else if (previous.end.inMilliseconds != values.end) {
                          // The end value changed
                          musicPlayer.seek(
                            Duration(milliseconds: values.end.toInt()),
                          );
                        }
                      }),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoopSliderTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  const LoopSliderTrackShape({
    required this.style,
    this.height = 24,
    this.outlineWidth,
  });

  final double height;
  final double? outlineWidth;

  final LoopStyle style;

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
      begin: style.disabledOutlineColor,
      end: style.outlineColor,
    );
    final ColorTween trackColorTween = ColorTween(
      begin: style.disabledInactiveLoopedTrackColor,
      end: style.inactiveLoopedTrackColor,
    );
    final Paint outlinePaint = Paint()
      ..color = outlineColorTween.evaluate(enableAnimation)!;
    final Paint trackPaint = Paint()
      ..color = trackColorTween.evaluate(enableAnimation)!;

    final (Offset leftThumbOffset, Offset rightThumbOffset) =
        switch (textDirection) {
      TextDirection.ltr => (startThumbCenter, endThumbCenter),
      TextDirection.rtl => (endThumbCenter, startThumbCenter),
    };
    final Size thumbSize =
        sliderTheme.rangeThumbShape!.getPreferredSize(isEnabled, isDiscrete);
    final double thumbRadius = thumbSize.width / 2;
    assert(thumbRadius > 0);

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    // Draw track
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
        topLeft: trackRadius,
        bottomLeft: trackRadius,
        topRight: trackRadius,
        bottomRight: trackRadius,
      ),
      trackPaint,
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
        trackRect.center.dy + height / 2 - (outlineWidth ?? style.outlineWidth),
      ),
      outlinePaint,
    );
    context.canvas.drawRect(
      Rect.fromLTRB(
        leftThumbOffset.dx,
        trackRect.center.dy - height / 2 + (outlineWidth ?? style.outlineWidth),
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
  });

  final Size size;
  final Radius radius;

  final LoopStyle style;

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
      begin: style.disabledOutlineColor,
      end: style.outlineColor,
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
