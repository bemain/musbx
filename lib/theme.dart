import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musbx/songs/loop_style.dart';

const Color defaultSeed = Color(0xff578cff);

Future<(ThemeData light, ThemeData dark)> generateThemes() async {
  // Defaults
  final ColorScheme lightDefault = ColorScheme.fromSeed(
    seedColor: defaultSeed,
  );
  final ColorScheme darkDefault = ColorScheme.fromSeed(
    seedColor: defaultSeed,
    brightness: Brightness.dark,
  );

  // Get color schemes
  var corePalette = await DynamicColorPlugin.getCorePalette();

  final (ColorScheme? lightScheme, ColorScheme? darkScheme) = (
    corePalette?.toColorScheme(),
    corePalette?.toColorScheme(brightness: Brightness.dark),
  );

  // Create themes
  final ThemeData lightTheme = ThemeData.from(
    colorScheme: lightScheme ?? lightDefault,
    useMaterial3: true,
  );
  final ThemeData darkTheme = ThemeData.from(
    colorScheme: darkScheme ?? darkDefault,
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
