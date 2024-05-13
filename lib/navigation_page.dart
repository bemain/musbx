import 'package:advanced_in_app_review/advanced_in_app_review.dart';
import 'package:flutter/material.dart';
import 'package:musbx/custom_icons.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/music_player/music_player_page.dart';
import 'package:musbx/tuner/tuner_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationPage extends StatefulWidget {
  /// Navigation page offering a bottom bar for switching between the different pages.
  const NavigationPage({super.key});

  @override
  State<StatefulWidget> createState() => NavigationPageState();
}

class NavigationPageState extends State<NavigationPage> {
  SharedPreferences? _preferences;

  int get currentIndex => _currentIndex;
  set currentIndex(int value) {
    _currentIndex = value;
    _preferences?.setInt("openPage", value);
  }

  int _currentIndex = 1;

  final PageController controller = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();

    () async {
      // Restore last open page
      _preferences = await SharedPreferences.getInstance();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        controller.jumpToPage(_preferences?.getInt("openPage") ?? currentIndex);
      });
    }();

    // Setup in-app review
    AdvancedInAppReview()
        .setMinDaysBeforeRemind(7)
        .setMinDaysAfterInstall(7)
        .setMinLaunchTimes(5)
        .setMinSecondsBeforeShowDialog(4)
        .monitor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
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
        selectedIndex: currentIndex,
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
