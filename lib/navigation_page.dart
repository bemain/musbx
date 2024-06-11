import 'package:flutter/material.dart';
import 'package:musbx/custom_icons.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/music_player/music_player_page.dart';
import 'package:musbx/persistent_value.dart';
import 'package:musbx/tuner/tuner_page.dart';

class NavigationPage extends StatefulWidget {
  /// Navigation page offering a bottom bar for switching between the different pages.
  const NavigationPage({super.key});

  @override
  State<StatefulWidget> createState() => NavigationPageState();
}

class NavigationPageState extends State<NavigationPage> {
  final PersistentValue<int> currentIndex = PersistentValue(
    "openPage",
    initialValue: 1,
  );

  final PageController controller = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();

    // Restore last open page
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.jumpToPage(currentIndex.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            currentIndex.value = index;
          });
        },
        children: [
          const MetronomePage(),
          MusicPlayerPage(),
          const TunerPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          controller.jumpToPage(index);
        },
        selectedIndex: currentIndex.value,
        destinations: const [
          NavigationDestination(
            label: "Metronome",
            icon: Icon(CustomIcons.metronome),
          ),
          NavigationDestination(
            label: "Music player",
            icon: Icon(Icons.music_note),
          ),
          NavigationDestination(
            label: "Tuner",
            icon: Icon(CustomIcons.tuning_fork),
          ),
        ],
      ),
    );
  }
}
