import 'package:flutter/material.dart';

/// Holds the colors and shape for a [CircularSlider].
class CircularSliderTheme {
  /// The height of the [Slider] track.
  final double trackHeight;

  /// Additional height, added to [trackHeight], for the active part of the track.
  final double activeTrackAdditionalHeight;

  /// The radius of the thumb.
  final double thumbRadius;

  /// The color of the [Slider] track between the [Slider.min] position and the
  /// current thumb position.
  final Color activeTrackColor;

  /// The color of the [Slider] track between the current thumb position and the
  /// [Slider.max] position.
  final Color inactiveTrackColor;

  /// The color of the [Slider] track between the [Slider.min] position and the
  /// current thumb position when the [Slider] is disabled.
  final Color disabledActiveTrackColor;

  /// The color of the [Slider] track between the current thumb position and the
  /// [Slider.max] position when the [Slider] is disabled.
  final Color disabledInactiveTrackColor;

  /// The color of the track's tick marks that are drawn between the [Slider.min]
  /// position and the current thumb position.
  final Color activeTickMarkColor;

  /// The color of the track's tick marks that are drawn between the current
  /// thumb position and the [Slider.max] position.
  final Color inactiveTickMarkColor;

  /// The color of the track's tick marks that are drawn between the [Slider.min]
  /// position and the current thumb position when the [Slider] is disabled.
  final Color disabledActiveTickMarkColor;

  /// The color of the track's tick marks that are drawn between the current
  /// thumb position and the [Slider.max] position when the [Slider] is
  /// disabled.
  final Color disabledInactiveTickMarkColor;

  /// The color of the thumb.
  final Color thumbColor;

  /// The color of the thumb when the [Slider] is disabled.
  final Color disabledThumbColor;

  /// The color of the overlay drawn around the slider thumb when it is
  /// pressed, focused, or hovered.
  ///
  /// This is typically a semi-transparent color.
  final Color overlayColor;

  /// Create [CircularSliderTheme] based on the given [theme] and [sliderTheme].
  CircularSliderTheme.fromThemes(
    ThemeData theme,
    SliderThemeData sliderTheme, {
    this.thumbRadius = 10.0,
    this.activeTrackAdditionalHeight = 2.0,
  })  : trackHeight = sliderTheme.trackHeight ?? 4.0,
        activeTrackColor =
            sliderTheme.activeTrackColor ?? theme.colorScheme.primary,
        inactiveTrackColor = sliderTheme.inactiveTrackColor ??
            theme.colorScheme.surfaceContainerHighest,
        disabledActiveTrackColor = sliderTheme.disabledActiveTrackColor ??
            theme.colorScheme.onSurface.withAlpha(0x61),
        disabledInactiveTrackColor = sliderTheme.disabledInactiveTrackColor ??
            theme.colorScheme.onSurface.withAlpha(0x1f),
        activeTickMarkColor = sliderTheme.activeTickMarkColor ??
            theme.colorScheme.onPrimary.withAlpha(0x61),
        inactiveTickMarkColor = sliderTheme.inactiveTickMarkColor ??
            theme.colorScheme.onSurfaceVariant.withAlpha(0x61),
        disabledActiveTickMarkColor = sliderTheme.disabledActiveTickMarkColor ??
            theme.colorScheme.onSurface.withAlpha(0x61),
        disabledInactiveTickMarkColor =
            sliderTheme.disabledInactiveTickMarkColor ??
                theme.colorScheme.onSurface.withAlpha(0x61),
        thumbColor = sliderTheme.thumbColor ?? theme.colorScheme.primary,
        disabledThumbColor = sliderTheme.disabledThumbColor ??
            Color.alphaBlend(theme.colorScheme.onSurface.withAlpha(0x61),
                theme.colorScheme.surface),
        overlayColor = sliderTheme.overlayColor ??
            theme.colorScheme.primary.withAlpha(0x1f);
}
