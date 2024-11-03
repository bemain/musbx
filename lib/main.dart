import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/songs/player/music_player.dart';
import 'package:musbx/navigation_page.dart';
import 'package:musbx/utils/notifications.dart';
import 'package:musbx/utils/persistent_value.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PersistentValue.initialize();

  // Create audio service
  await MusicPlayer.instance.initAudioService();
  await Notifications.initialize();

  LaunchHandler.initialize();

  // Google Ads
  unawaited(MobileAds.instance.initialize());
  await Purchases.intialize();

  // Lock screen orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Generate themes
  await generateThemes(onThemesGenerated: (lightTheme, darkTheme) {
    // Run app
    runApp(MyApp(
      lightTheme: lightTheme,
      darkTheme: darkTheme,
    ));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.lightTheme, required this.darkTheme});

  /// The light [ColorScheme] obtained from the device, if any.
  final ThemeData lightTheme;

  /// The dark [ColorScheme] obtained from the device, if any.
  final ThemeData darkTheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Musician's Toolbox",
      theme: lightTheme,
      darkTheme: darkTheme,
      home: NavigationPage(),
    );
  }
}
