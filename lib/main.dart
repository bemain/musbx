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
      androidNotificationChannelId: 'se.agardh.musbx.channel.music_player',
      androidNotificationChannelName: 'Music player',
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
    lightDynamic: lightScheme,
    darkDynamic: darkScheme,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.lightDynamic, this.darkDynamic});

  /// The light [ColorScheme] obtained from the device, if any.
  final ColorScheme? lightDynamic;

  /// The dark [ColorScheme] obtained from the device, if any.
  final ColorScheme? darkDynamic;

  @override
  Widget build(BuildContext context) {
    final ColorScheme lightDefault = ColorScheme.fromSeed(
      seedColor: Colors.blue,
    );
    final ColorScheme darkDefault = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    final ThemeData lightTheme = ThemeData.from(
      colorScheme: lightDynamic ?? lightDefault,
      useMaterial3: true,
    );
    final ThemeData darkTheme = ThemeData.from(
      colorScheme: darkDynamic ?? darkDefault,
      useMaterial3: true,
    );

    return MaterialApp(
        title: "Musician's Toolbox",
        theme: lightTheme.copyWith(
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
