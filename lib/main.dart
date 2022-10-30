import 'package:audio_service/audio_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musbx/navigation_screen.dart';
import 'package:musbx/music_player/audio_handler.dart';

Future<void> main() async {
  // Create audio service
  MusicPlayerAudioHandler.instance = await AudioService.init(
    builder: () => MusicPlayerAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'se.agardh.musbx.channel.audio',
      androidNotificationChannelName: 'Musbx',
    ),
  );

  // Lock screen orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Get color schemes
  var corePalette = await DynamicColorPlugin.getCorePalette();
  final ColorScheme? lightScheme = corePalette?.toColorScheme();
  final ColorScheme? darkScheme =
      corePalette?.toColorScheme(brightness: Brightness.dark);

  runApp(MyApp(
    lightColorScheme: lightScheme,
    darkColorScheme: darkScheme,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.lightColorScheme, this.darkColorScheme});

  final ColorScheme? lightColorScheme;
  final ColorScheme? darkColorScheme;

  @override
  Widget build(BuildContext context) {
    ThemeData lightTheme = ThemeData.from(
        colorScheme: lightColorScheme ??
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
            ),
        useMaterial3: true);
    ThemeData darkTheme = ThemeData.from(
        colorScheme: darkColorScheme ??
            ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
        useMaterial3: true);

    return MaterialApp(
        title: "Musician's Toolbox",
        theme: lightTheme.copyWith(
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
            ),
          ),
          sliderTheme: lightTheme.sliderTheme.copyWith(
            showValueIndicator: ShowValueIndicator.always,
          ),
        ),
        darkTheme: darkTheme.copyWith(
          sliderTheme: darkTheme.sliderTheme.copyWith(
            showValueIndicator: ShowValueIndicator.always,
          ),
        ),
        home: const NavigationScreen());
  }
}
