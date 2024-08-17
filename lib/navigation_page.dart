import 'package:flutter/material.dart';
import 'package:musbx/ads.dart';
import 'package:musbx/custom_icons.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/music_player/music_player_page.dart';
import 'package:musbx/persistent_value.dart';
import 'package:musbx/purchases.dart';
import 'package:musbx/tuner/tuner_page.dart';

/// The key of the [MusicPlayerPage]. Can be used to show dialogs.
final GlobalKey<NavigationPageState> navigationPageKey = GlobalKey();

class NavigationPage extends StatefulWidget {
  /// Navigation page offering a bottom bar for switching between the different pages.
  NavigationPage() : super(key: navigationPageKey);

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

    // When premium features are unlocked, rebuild the entire UI.
    Purchases.hasPremiumNotifier.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  currentIndex.value = index;
                });
              },
              children: const [
                MetronomePage(),
                MusicPlayerPage(),
                TunerPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO: Remove bottom padding caused by SafeArea, which leaves a big space between the NavigationBar and the banner ad.
          NavigationBar(
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
                label: "Transcribe",
                icon: Icon(Icons.music_note),
              ),
              NavigationDestination(
                label: "Tuner",
                icon: Icon(CustomIcons.tuning_fork),
              ),
            ],
          ),
          if (!Purchases.hasPremium)
            const SafeArea(
              top: false,
              child: BannerAdWidget(),
            ),
        ],
      ),
    );
  }
}
