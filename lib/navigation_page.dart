import 'package:flutter/material.dart';
import 'package:musbx/widgets/ads.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/drone/drone_page.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/songs/music_player_page.dart';
import 'package:musbx/utils/persistent_value.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/tuner/tuner_page.dart';
import 'package:musbx/widgets/widgets.dart';

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

  /// The height of the bottom bar.
  /// This is subtracted from the [MediaQuery.viewInsets] passed to the children
  /// of this widget, to compensate for the fact that we use double scaffolds.
  double bottomBarHeight = kBottomNavigationBarHeight;

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
      primary: false,
      resizeToAvoidBottomInset: false,
      body: MediaQuery(
        // Compensate for the fact that we have double Scaffolds
        data: MediaQuery.of(context).copyWith(
          viewInsets: MediaQuery.viewInsetsOf(context).copyWith(
            bottom: MediaQuery.viewInsetsOf(context).bottom - bottomBarHeight,
          ),
        ),
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
            DronePage(),
          ],
        ),
      ),
      bottomNavigationBar: MeasureSize(
        onSizeChanged: (Size size) {
          bottomBarHeight = size.height;
        },
        child: Column(
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
                  label: "Songs",
                  icon: Icon(Icons.music_note),
                ),
                NavigationDestination(
                  label: "Tuner",
                  icon: Icon(Icons.speed),
                ),
                NavigationDestination(
                  label: "Drone",
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
      ),
    );
  }
}
