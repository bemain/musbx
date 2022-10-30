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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
      ThemeData lightThemeDynamic = ThemeData.from(
          colorScheme: lightDynamic ?? const ColorScheme.light(),
          useMaterial3: true);
      ThemeData darkThemeDynamic = ThemeData.from(
          colorScheme: darkDynamic ?? const ColorScheme.dark(),
          useMaterial3: true);

      return MaterialApp(
          title: "Musician's Toolbox",
          theme: lightThemeDynamic.copyWith(
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
              ),
            ),
            sliderTheme: lightThemeDynamic.sliderTheme.copyWith(
              showValueIndicator: ShowValueIndicator.always,
            ),
          ),
          darkTheme: darkThemeDynamic.copyWith(
            sliderTheme: darkThemeDynamic.sliderTheme.copyWith(
              showValueIndicator: ShowValueIndicator.always,
            ),
          ),
          home: const NavigationScreen());
    });
  }
}
