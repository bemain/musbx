import 'package:flutter/material.dart';

class PositionSliderStyle extends ThemeExtension<PositionSliderStyle> {
  const PositionSliderStyle({
    required this.activeLoopedTrackColor,
    required this.inactiveLoopedTrackColor,
    required this.disabledActiveLoopedTrackColor,
    required this.disabledInactiveLoopedTrackColor,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.disabledActiveTrackColor,
    required this.disabledInactiveTrackColor,
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
      activeLoopedTrackColor: theme.colorScheme.primary,
      inactiveLoopedTrackColor: theme.colorScheme.primary.withAlpha(0x1f),
      disabledActiveLoopedTrackColor: theme.colorScheme.onSurface.withAlpha(
        0x61,
      ),
      disabledInactiveLoopedTrackColor: theme.colorScheme.onSurface.withAlpha(
        0x1f,
      ),
      activeTrackColor: theme.colorScheme.surfaceContainer,
      inactiveTrackColor: theme.colorScheme.surfaceContainer,
      disabledActiveTrackColor: theme.colorScheme.onSurface.withAlpha(0x1f),
      disabledInactiveTrackColor: theme.colorScheme.onSurface.withAlpha(0x1f),
    );
  }

  final Color activeLoopedTrackColor;
  final Color disabledActiveLoopedTrackColor;

  final Color inactiveLoopedTrackColor;
  final Color disabledInactiveLoopedTrackColor;

  final Color activeTrackColor;
  final Color disabledActiveTrackColor;

  final Color inactiveTrackColor;
  final Color disabledInactiveTrackColor;

  @override
  ThemeExtension<PositionSliderStyle> copyWith({
    Color? activeLoopedTrackColor,
    Color? inactiveLoopedTrackColor,
    Color? disabledActiveLoopedTrackColor,
    Color? disabledInactiveLoopedTrackColor,
    Color? activeTrackColor,
    Color? inactiveTrackColor,
    Color? disabledActiveTrackColor,
    Color? disabledInactiveTrackColor,
  }) {
    return PositionSliderStyle(
      activeLoopedTrackColor:
          activeLoopedTrackColor ?? this.activeLoopedTrackColor,
      inactiveLoopedTrackColor:
          inactiveLoopedTrackColor ?? this.inactiveLoopedTrackColor,
      disabledActiveLoopedTrackColor:
          disabledActiveLoopedTrackColor ??
          this.disabledActiveLoopedTrackColor,
      disabledInactiveLoopedTrackColor:
          disabledInactiveLoopedTrackColor ??
          this.disabledInactiveLoopedTrackColor,
      activeTrackColor: activeTrackColor ?? this.activeTrackColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      disabledActiveTrackColor:
          disabledActiveTrackColor ?? this.disabledActiveTrackColor,
      disabledInactiveTrackColor:
          disabledInactiveTrackColor ?? this.disabledInactiveTrackColor,
    );
  }

  @override
  ThemeExtension<PositionSliderStyle> lerp(
    covariant PositionSliderStyle? other,
    double t,
  ) {
    return PositionSliderStyle(
      activeLoopedTrackColor: Color.lerp(
        activeLoopedTrackColor,
        other!.activeLoopedTrackColor,
        t,
      )!,
      inactiveLoopedTrackColor: Color.lerp(
        inactiveLoopedTrackColor,
        other.inactiveLoopedTrackColor,
        t,
      )!,
      disabledActiveLoopedTrackColor: Color.lerp(
        disabledActiveLoopedTrackColor,
        other.disabledActiveLoopedTrackColor,
        t,
      )!,
      disabledInactiveLoopedTrackColor: Color.lerp(
        disabledInactiveLoopedTrackColor,
        other.disabledInactiveLoopedTrackColor,
        t,
      )!,
      activeTrackColor: Color.lerp(
        activeTrackColor,
        other.activeTrackColor,
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
    );
  }
}
