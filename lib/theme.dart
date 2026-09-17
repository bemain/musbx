import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';

/// The app's light and dark themes.
abstract final class AppTheme {
  /// The colour the themes are generated from when the platform offers no dynamic
  /// colours.
  static const Color defaultSeed = Color(0xff578cff);

  /// Build both themes, seeding them from the platform's dynamic colours when it
  /// has any.
  static (ThemeData light, ThemeData dark) generate(
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  ) {
    // Defaults
    final ColorScheme lightDefault = ColorScheme.fromSeed(
      seedColor: defaultSeed,
    );
    final ColorScheme darkDefault = ColorScheme.fromSeed(
      seedColor: defaultSeed,
      brightness: Brightness.dark,
    );

    // Create themes
    final ThemeData lightTheme = ThemeData.from(
      colorScheme: lightDynamic ?? lightDefault,
      useMaterial3: true,
    );
    final ThemeData darkTheme = ThemeData.from(
      colorScheme: darkDynamic ?? darkDefault,
      useMaterial3: true,
    );

    return (
      lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(lightTheme.textTheme),
        sliderTheme: lightTheme.sliderTheme.copyWith(
          showValueIndicator: ShowValueIndicator.onDrag,
        ),
        iconTheme: lightTheme.iconTheme.copyWith(weight: 600),
        switchTheme: lightTheme.switchTheme.copyWith(
          thumbIcon: WidgetStateProperty<Icon>.fromMap(
            const <WidgetStatesConstraint, Icon>{
              WidgetState.selected: Icon(Symbols.check),
              WidgetState.any: Icon(Symbols.close),
            },
          ),
        ),
        progressIndicatorTheme: lightTheme.progressIndicatorTheme.copyWith(
          year2023: false,
        ),
        extensions: [PositionSliderStyle.fromTheme(theme: lightTheme)],
      ),
      darkTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(darkTheme.textTheme),
        sliderTheme: darkTheme.sliderTheme.copyWith(
          year2023: false,
          showValueIndicator: ShowValueIndicator.onDrag,
        ),
        iconTheme: darkTheme.iconTheme.copyWith(weight: 600),
        switchTheme: darkTheme.switchTheme.copyWith(
          thumbIcon: WidgetStateProperty<Icon>.fromMap(
            const <WidgetStatesConstraint, Icon>{
              WidgetState.selected: Icon(Symbols.check),
              WidgetState.any: Icon(Symbols.close),
            },
          ),
        ),
        progressIndicatorTheme: darkTheme.progressIndicatorTheme.copyWith(
          year2023: false,
        ),
        extensions: [PositionSliderStyle.fromTheme(theme: darkTheme)],
      ),
    );
  }
}
