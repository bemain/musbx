import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/theme.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/utils/notifications.dart';
import 'package:musbx/utils/persistent_value.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PersistentValue.initialize();
  await Directories.initialize();

  // Create audio service
  await Songs.initialize();
  await Notifications.initialize();

  LaunchHandler.initialize();

  // Google Ads
  unawaited(MobileAds.instance.initialize());
  await Purchases.intialize();

  // Lock screen orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final (ThemeData lightTheme, ThemeData darkTheme) =
            generateThemes(lightDynamic, darkDynamic);

        return MaterialApp.router(
          title: "Musician's Toolbox",
          theme: lightTheme,
          darkTheme: darkTheme,
          routerConfig: Navigation.router,
          restorationScopeId: "app",
        );
      },
    );
  }
}
