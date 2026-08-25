import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/data/services/ad_service.dart';
import 'package:musbx/data/services/analytics_service.dart';
import 'package:musbx/data/services/deep_links_service.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/notification_service.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/data/services/purchase_service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/data/services/soundcloud_api_client.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/theme.dart';
import 'package:musbx/utils/deep_links.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/utils/notifications.dart';
import 'package:musbx/utils/purchases.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferencesService.initialize();
  await FileCacheService.initialize();
  await SupabaseService.initialize();
  await PermissionService.initialize();
  await AnalyticsService.initialize();
  await AdService.initialize();
  await PurchaseService.initialize();
  await Purchases.intialize();

  await Songs.initialize();
  await NotificationService.initialize();
  await Notifications.initialize();

  await SoundCloudApiClient.initialize();

  await DeepLinksService.initialize();
  await DeepLinks.initialize();

  await LaunchHandler.initialize();

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
