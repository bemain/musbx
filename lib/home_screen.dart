import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome_screen.dart';
import 'package:musbx/music_player/music_player_screen.dart';
import 'package:musbx/tuner/tuner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          const MetronomeScreen(),
          MusicPlayerScreen(),
          const TunerScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        currentIndex: selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "Metronome",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note_rounded),
            label: "Music player",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_rounded),
            label: "Tuner",
          ),
        ],
      ),
    );
  }
}
