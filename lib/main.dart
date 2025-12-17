import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/analytics.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/theme.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/utils/notifications.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PersistentValue.initialize();
  await Directories.initialize();

  await Analytics.initialize();

  await Songs.initialize();
  await Notifications.initialize();

  await LaunchHandler.initialize();

  // Google Ads
  if (Platform.isAndroid || Platform.isIOS) {
    unawaited(MobileAds.instance.initialize());
  }
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
      builder: (lightDynamic, darkDynamic) {
        final (
          ThemeData lightTheme,
          ThemeData darkTheme,
        ) = AppTheme.generate(
          lightDynamic,
          darkDynamic,
        );

        return ValueListenableBuilder(
          valueListenable: AppTheme.themeModeNotifier,
          builder: (context, themeMode, child) => MaterialApp.router(
            title: "Musician's Toolbox",
            theme: lightTheme,
            darkTheme: darkTheme,
            routerConfig: Navigation.router,
            themeMode: themeMode,
            restorationScopeId: "app",
            builder: (context, child) {
              final ColorScheme colors = Theme.of(context).colorScheme;

              return Shimmer(
                gradient: LinearGradient(
                  colors: [
                    colors.surfaceContainer,
                    colors.surfaceContainerLow,
                    colors.surfaceContainer,
                  ],
                  stops: [0.1, 0.3, 0.4],
                  begin: Alignment(-1.0, -0.3),
                  end: Alignment(1.0, 0.3),
                  tileMode: TileMode.clamp,
                ),
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}
