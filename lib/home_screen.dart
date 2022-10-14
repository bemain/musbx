import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome_screen.dart';
import 'package:musbx/music_player/music_player_screen.dart';
import 'package:musbx/tuner/tuner_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Home screen offering a bottom bar for switching between the different screens.
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Widget> screens = const [
    MetronomeScreen(),
    MusicPlayerScreen(),
    TunerScreen(),
  ];
  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        currentIndex: selectedIndex,
        items: const [
          BottomNavigationBarItem(
            label: "Metronome",
            icon: Icon(Icons.more_horiz),
          ),
          BottomNavigationBarItem(
            label: "Music player",
            icon: Icon(Icons.music_note_rounded),
          ),
          BottomNavigationBarItem(
            label: "Tuner",
            icon: Icon(Icons.speed_rounded),
          ),
        ],
      ),
    );
  }
}
