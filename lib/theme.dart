import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

const Color defaultSeed = Color(0xff578cff);

Future<void> generateThemes({
  required Function(ThemeData light, ThemeData dark) onThemesGenerated,
}) async {
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

  onThemesGenerated(lightTheme, darkTheme);
}
