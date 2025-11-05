import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musbx/songs/song_page/position_slider_style.dart';
import 'package:musbx/utils/persistent_value.dart';

class AppTheme {
  const AppTheme._();

  static const Color defaultSeed = Color(0xff578cff);

  /// The theme mode currently used by the app.
  static ThemeMode get themeMode => themeModeNotifier.value;
  static final TransformedPersistentValue<ThemeMode, String>
  themeModeNotifier = TransformedPersistentValue(
    "theme/mode",
    initialValue: ThemeMode.system,
    to: (value) => value.name,
    from: (value) => switch (value) {
      "dark" => ThemeMode.dark,
      "light" => ThemeMode.light,
      _ => ThemeMode.system,
    },
  );

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
            <WidgetStatesConstraint, Icon>{
              WidgetState.selected: Icon(Icons.check),
              WidgetState.any: Icon(Icons.close),
            },
          ),
        ),
        extensions: [PositionSliderStyle.fromTheme(theme: lightTheme)],
      ),
      darkTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(darkTheme.textTheme),
        sliderTheme: darkTheme.sliderTheme.copyWith(
          showValueIndicator: ShowValueIndicator.onDrag,
        ),
        iconTheme: darkTheme.iconTheme.copyWith(weight: 600),
        switchTheme: darkTheme.switchTheme.copyWith(
          thumbIcon: WidgetStateProperty<Icon>.fromMap(
            <WidgetStatesConstraint, Icon>{
              WidgetState.selected: Icon(Icons.check),
              WidgetState.any: Icon(Icons.close),
            },
          ),
        ),
        extensions: [PositionSliderStyle.fromTheme(theme: darkTheme)],
      ),
    );
  }
}
