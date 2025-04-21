import 'package:flutter/material.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';

class LoopSlider extends StatelessWidget {
  /// Range slider for selecting the section to loop.
  LoopSlider({super.key});

  final SongPlayer player = Songs.player!;

  @override
  Widget build(BuildContext context) {
    bool wasPlayingBeforeChange = false;

    return ListenableBuilder(
      listenable: player.loop,
      builder: (context, _) {
        PositionSliderStyle style =
            Theme.of(context).extension<PositionSliderStyle>()!;

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
              labels: RangeLabels(
                player.loop.start.toString().substring(2, 10),
                player.loop.end.toString().substring(2, 10),
              ),
              min: 0,
              max: player.duration.inMilliseconds.toDouble(),
              values: RangeValues(
                player.loop.start.inMilliseconds.toDouble(),
                player.loop.end.inMilliseconds.toDouble(),
              ),
              onChangeStart: (value) {
                wasPlayingBeforeChange = player.isPlaying;
                player.pause();
              },
              onChangeEnd: (value) {
                if (wasPlayingBeforeChange) player.resume();
              },
              onChanged: (RangeValues values) {
                final Duration previousStart = player.loop.start;
                final Duration previousEnd = player.loop.end;

                // Update section
                player.loop.start =
                    Duration(milliseconds: values.start.toInt());
                player.loop.end = Duration(milliseconds: values.end.toInt());

                if (previousStart.inMilliseconds != values.start) {
                  // The start value changed
                  player.seek(
                    Duration(milliseconds: values.start.toInt()),
                  );
                } else if (previousEnd.inMilliseconds != values.end) {
                  // The end value changed
                  player.seek(
                    Duration(milliseconds: values.end.toInt()),
                  );
                }
              }),
        );
      },
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
