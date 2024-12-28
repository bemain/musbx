import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musbx/songs/loop_style.dart';

const Color defaultSeed = Color(0xff578cff);

(ThemeData light, ThemeData dark) generateThemes(
    ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
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
        showValueIndicator: ShowValueIndicator.always,
      ),
      iconTheme: lightTheme.iconTheme.copyWith(weight: 600),
      extensions: [LoopStyle.fromTheme(theme: lightTheme)],
    ),
    darkTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(darkTheme.textTheme),
      sliderTheme: darkTheme.sliderTheme.copyWith(
        showValueIndicator: ShowValueIndicator.always,
      ),
      iconTheme: darkTheme.iconTheme.copyWith(weight: 600),
      extensions: [LoopStyle.fromTheme(theme: darkTheme)],
    ),
  );
}
