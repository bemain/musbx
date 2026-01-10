import 'package:flutter/material.dart';

class PositionSliderStyle extends ThemeExtension<PositionSliderStyle> {
  const PositionSliderStyle({
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.disabledActiveTrackColor,
    required this.disabledInactiveTrackColor,
    required this.nonLoopedTrackColor,
    required this.disabledNonLoopedTrackColor,
  });

  /// Generates a SliderThemeData from three main colors.
  ///
  /// Usually these are the primary, dark and light colors from
  /// a [ThemeData].
  ///
  /// The opacities of these colors will be overridden with the Material Design
  /// defaults when assigning them to the slider theme component colors.
  ///
  /// This is used to generate the default slider theme for a [ThemeData].
  factory PositionSliderStyle.fromTheme({
    required ThemeData theme,
  }) {
    return PositionSliderStyle(
      activeTrackColor: theme.colorScheme.primary,
      inactiveTrackColor: theme.colorScheme.secondaryContainer,
      disabledActiveTrackColor: theme.colorScheme.onSurface.withAlpha(
        0x61,
      ),
      disabledInactiveTrackColor: theme.colorScheme.onSurface.withAlpha(
        0x1f,
      ),
      nonLoopedTrackColor: theme.colorScheme.surfaceContainer,
      disabledNonLoopedTrackColor: theme.colorScheme.onSurface.withAlpha(0x1f),
    );
  }

  final Color activeTrackColor;
  final Color disabledActiveTrackColor;

  final Color inactiveTrackColor;
  final Color disabledInactiveTrackColor;

  final Color nonLoopedTrackColor;
  final Color disabledNonLoopedTrackColor;

  @override
  ThemeExtension<PositionSliderStyle> copyWith({
    Color? activeTrackColor,
    Color? inactiveTrackColor,
    Color? disabledActiveTrackColor,
    Color? disabledInactiveTrackColor,
    Color? nonLoopedTrackColor,
    Color? disabledNonLoopedTrackColor,
  }) {
    return PositionSliderStyle(
      activeTrackColor: activeTrackColor ?? this.activeTrackColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      disabledActiveTrackColor:
          disabledActiveTrackColor ?? this.disabledActiveTrackColor,
      disabledInactiveTrackColor:
          disabledInactiveTrackColor ?? this.disabledInactiveTrackColor,
      nonLoopedTrackColor: activeTrackColor ?? this.nonLoopedTrackColor,
      disabledNonLoopedTrackColor:
          disabledActiveTrackColor ?? this.disabledNonLoopedTrackColor,
    );
  }

  @override
  ThemeExtension<PositionSliderStyle> lerp(
    covariant PositionSliderStyle? other,
    double t,
  ) {
    return PositionSliderStyle(
      activeTrackColor: Color.lerp(
        activeTrackColor,
        other!.activeTrackColor,
        t,
      )!,
      inactiveTrackColor: Color.lerp(
        inactiveTrackColor,
        other.inactiveTrackColor,
        t,
      )!,
      disabledActiveTrackColor: Color.lerp(
        disabledActiveTrackColor,
        other.disabledActiveTrackColor,
        t,
      )!,
      disabledInactiveTrackColor: Color.lerp(
        disabledInactiveTrackColor,
        other.disabledInactiveTrackColor,
        t,
      )!,
      nonLoopedTrackColor: Color.lerp(
        nonLoopedTrackColor,
        other.nonLoopedTrackColor,
        t,
      )!,
      disabledNonLoopedTrackColor: Color.lerp(
        disabledNonLoopedTrackColor,
        other.disabledNonLoopedTrackColor,
        t,
      )!,
    );
  }
}
