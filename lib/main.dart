import 'package:audio_service/audio_service.dart';
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
    return MaterialApp(
        title: "Musician's Toolbox",
        theme: ThemeData.light(useMaterial3: true).copyWith(
          colorScheme: ThemeData.light(useMaterial3: true).colorScheme.copyWith(
                primary: Colors.blue,
                primaryContainer: Colors.blueAccent,
                secondary: Colors.amber,
                secondaryContainer: Colors.amberAccent,
                tertiary: Colors.green,
                tertiaryContainer: Colors.lightGreen,
                background: Colors.grey,
                onBackground: Colors.grey[700],
              ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
            ),
          ),
          sliderTheme: ThemeData.light(useMaterial3: true).sliderTheme.copyWith(
                showValueIndicator: ShowValueIndicator.always,
              ),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ThemeData.dark(useMaterial3: true).colorScheme.copyWith(
                primary: Colors.blue,
                primaryContainer: Colors.blueAccent,
                secondary: Colors.amber,
                secondaryContainer: Colors.amberAccent,
                tertiary: Colors.green,
                tertiaryContainer: Colors.lightGreen,
                onBackground: Colors.black,
              ),
          sliderTheme: ThemeData.dark(useMaterial3: true).sliderTheme.copyWith(
                valueIndicatorColor: Colors.grey[700],
                showValueIndicator: ShowValueIndicator.always,
              ),
        ),
        home: const NavigationScreen());
  }
}
