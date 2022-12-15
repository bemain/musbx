import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

Future<void> generateThemes({
  required Function(ThemeData light, ThemeData dark) onThemesGenerated,
}) async {
  // Defaults
  final ColorScheme lightDefault = ColorScheme.fromSeed(
    seedColor: Colors.blue,
  );
  final ColorScheme darkDefault = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  );

  // Get color schemes
  var corePalette = await DynamicColorPlugin.getCorePalette();
  final ColorScheme lightScheme = corePalette?.toColorScheme() ?? lightDefault;
  final ColorScheme darkScheme =
      corePalette?.toColorScheme(brightness: Brightness.dark) ?? darkDefault;

  // Create themes
  final ThemeData lightTheme = ThemeData.from(
    colorScheme: lightScheme,
    useMaterial3: true,
  );
  final ThemeData darkTheme = ThemeData.from(
    colorScheme: darkScheme,
    useMaterial3: true,
  );

  onThemesGenerated(lightTheme, darkTheme);
}
