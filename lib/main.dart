import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musbx/metronome/bottom_bar.dart';
import 'package:musbx/metronome/metronome_screen.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_screen.dart';

Future<void> main() async {
  // Create audio service
  MusicPlayer.instance = MusicPlayer.internal(
    await AudioService.init(
      builder: () => JustAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'se.agardh.musbx.channel.audio',
        androidNotificationChannelName: 'Musbx',
      ),
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: MetronomeScreen(),
      ),
    );
  }
}
