import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musbx/home_screen.dart';
import 'package:musbx/music_player/audio_handler.dart';

Future<void> main() async {
  // Create audio service
  JustAudioHandler.instance = await AudioService.init(
    builder: () => JustAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'se.agardh.musbx.channel.audio',
      androidNotificationChannelName: 'Musbx',
    ),
  );

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
                secondary: Colors.deepPurple,
                secondaryContainer: Colors.purple,
                tertiary: Colors.green,
                tertiaryContainer: Colors.lightGreen,
                background: Colors.grey,
              ),
          sliderTheme: const SliderThemeData(
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
                background: Colors.grey,
              ),
          sliderTheme: const SliderThemeData(
            showValueIndicator: ShowValueIndicator.always,
          ),
        ),
        home: const HomeScreen());
  }
}
