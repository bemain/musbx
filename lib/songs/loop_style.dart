import 'dart:ui';

import 'package:flutter/material.dart';

class LoopStyle extends ThemeExtension<LoopStyle> {
  const LoopStyle({
    required this.activeLoopedTrackColor,
    required this.inactiveLoopedTrackColor,
    required this.disabledActiveLoopedTrackColor,
    required this.disabledInactiveLoopedTrackColor,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.disabledActiveTrackColor,
    required this.disabledInactiveTrackColor,
    required this.overlayColor,
    required this.outlineColor,
    required this.disabledOutlineColor,
    required this.outlineRadius,
    required this.outlineWidth,
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
  factory LoopStyle.fromTheme({
    required ThemeData theme,
  }) {
    return LoopStyle(
      activeLoopedTrackColor: theme.colorScheme.primary,
      inactiveLoopedTrackColor: theme.colorScheme.primary.withAlpha(0x1f),
      disabledActiveLoopedTrackColor:
          theme.colorScheme.onSurface.withAlpha(0x61),
      disabledInactiveLoopedTrackColor:
          theme.colorScheme.onSurface.withAlpha(0x1f),
      activeTrackColor: theme.colorScheme.surfaceContainer,
      inactiveTrackColor: theme.colorScheme.surfaceContainer,
      disabledActiveTrackColor: theme.colorScheme.onSurface.withAlpha(0x1f),
      disabledInactiveTrackColor: theme.colorScheme.onSurface.withAlpha(0x1f),
      overlayColor: theme.colorScheme.primary.withAlpha(0x1f),
      outlineColor: theme.colorScheme.primary, // TODO: Use a different color
      disabledOutlineColor: theme.colorScheme.onSurface.withAlpha(0x1f),
      outlineRadius: const Radius.circular(16.0),
      outlineWidth: 2.0,
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

  final Color overlayColor;

  final Color outlineColor;
  final Color disabledOutlineColor;
  final Radius outlineRadius;
  final double outlineWidth;

  @override
  ThemeExtension<LoopStyle> copyWith({
    Color? activeLoopedTrackColor,
    Color? inactiveLoopedTrackColor,
    Color? disabledActiveLoopedTrackColor,
    Color? disabledInactiveLoopedTrackColor,
    Color? activeTrackColor,
    Color? inactiveTrackColor,
    Color? disabledActiveTrackColor,
    Color? disabledInactiveTrackColor,
    Color? overlayColor,
    Color? outlineColor,
    Color? disabledOutlineColor,
    Radius? outlineRadius,
    double? outlineWidth,
  }) {
    return LoopStyle(
      activeLoopedTrackColor:
          activeLoopedTrackColor ?? this.activeLoopedTrackColor,
      inactiveLoopedTrackColor:
          inactiveLoopedTrackColor ?? this.inactiveLoopedTrackColor,
      disabledActiveLoopedTrackColor:
          disabledActiveLoopedTrackColor ?? this.disabledActiveLoopedTrackColor,
      disabledInactiveLoopedTrackColor: disabledInactiveLoopedTrackColor ??
          this.disabledInactiveLoopedTrackColor,
      activeTrackColor: activeTrackColor ?? this.activeTrackColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      disabledActiveTrackColor:
          disabledActiveTrackColor ?? this.disabledActiveTrackColor,
      disabledInactiveTrackColor:
          disabledInactiveTrackColor ?? this.disabledInactiveTrackColor,
      overlayColor: overlayColor ?? this.overlayColor,
      outlineColor: outlineColor ?? this.outlineColor,
      disabledOutlineColor: disabledOutlineColor ?? this.disabledOutlineColor,
      outlineRadius: outlineRadius ?? this.outlineRadius,
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }

  @override
  ThemeExtension<LoopStyle> lerp(covariant LoopStyle? other, double t) {
    return LoopStyle(
      activeLoopedTrackColor:
          Color.lerp(activeLoopedTrackColor, other!.activeLoopedTrackColor, t)!,
      inactiveLoopedTrackColor: Color.lerp(
          inactiveLoopedTrackColor, other.inactiveLoopedTrackColor, t)!,
      disabledActiveLoopedTrackColor: Color.lerp(disabledActiveLoopedTrackColor,
          other.disabledActiveLoopedTrackColor, t)!,
      disabledInactiveLoopedTrackColor: Color.lerp(
          disabledInactiveLoopedTrackColor,
          other.disabledInactiveLoopedTrackColor,
          t)!,
      activeTrackColor:
          Color.lerp(activeTrackColor, other.activeTrackColor, t)!,
      inactiveTrackColor:
          Color.lerp(inactiveTrackColor, other.inactiveTrackColor, t)!,
      disabledActiveTrackColor: Color.lerp(
          disabledActiveTrackColor, other.disabledActiveTrackColor, t)!,
      disabledInactiveTrackColor: Color.lerp(
          disabledInactiveTrackColor, other.disabledInactiveTrackColor, t)!,
      overlayColor: Color.lerp(overlayColor, other.overlayColor, t)!,
      outlineColor: Color.lerp(outlineColor, other.outlineColor, t)!,
      disabledOutlineColor:
          Color.lerp(disabledOutlineColor, other.disabledOutlineColor, t)!,
      outlineRadius: Radius.lerp(outlineRadius, other.outlineRadius, t)!,
      outlineWidth: lerpDouble(outlineWidth, other.outlineWidth, t)!,
    );
  }
}
