import 'package:flutter/material.dart';
import 'package:musbx/music_player/looper/looper.dart';
import 'package:musbx/music_player/music_player.dart';

class LoopSlider extends StatelessWidget {
  /// Range slider for selecting the section to loop.
  LoopSlider({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: musicPlayer.durationNotifier,
      builder: (_, duration, __) => ValueListenableBuilder(
        valueListenable: musicPlayer.looper.enabledNotifier,
        builder: (_, loopEnabled, __) => ValueListenableBuilder(
          valueListenable: musicPlayer.looper.sectionNotifier,
          builder: (context, loopSection, _) {
            return SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                    rangeThumbShape: const LoopSectionThumbShape(),
                    rangeTrackShape: const LoopSliderTrackShape(),
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
                onChanged: !loopEnabled
                    ? null
                    : musicPlayer.nullIfNoSongElse((RangeValues values) {
                        musicPlayer.looper.section = LoopSection(
                          start: Duration(milliseconds: values.start.toInt()),
                          end: Duration(milliseconds: values.end.toInt()),
                        );
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
  const LoopSliderTrackShape({this.height = 24, this.lineWidth = 1.0});

  final double height;

  final double lineWidth;

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
    final ColorTween activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

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
      inactivePaint,
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
        trackRect.center.dy + height / 2 - lineWidth,
      ),
      activePaint,
    );
    context.canvas.drawRect(
      Rect.fromLTRB(
        leftThumbOffset.dx,
        trackRect.center.dy - height / 2 + lineWidth,
        rightThumbOffset.dx,
        trackRect.center.dy - height / 2,
      ),
      activePaint,
    );
  }
}

class LoopSectionThumbShape extends RangeSliderThumbShape {
  const LoopSectionThumbShape({
    this.size = const Size(10, 24),
    this.radius = const Radius.circular(4),
  });

  final Size size;

  final Radius radius;

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
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
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
