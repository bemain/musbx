import 'package:flutter/material.dart';
import 'package:musbx/metronome/bottom_bar.dart';
import 'package:musbx/music_player/music_player_screen.dart';
import 'package:musbx/tuner/tuner_screen.dart';

void main() {
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
        body: MusicPlayerScreen(),
        bottomNavigationBar: MetronomeBottomBar(),
      ),
    );
  }
}
