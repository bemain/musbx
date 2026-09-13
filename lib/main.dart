import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/config/dependencies.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/data/services/analytics_service.dart';
import 'package:musbx/domain/use_case/resume_demixing.dart';
import 'package:musbx/routing/router.dart';
import 'package:musbx/theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final providers = await loadProviders();

  // Lock screen orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: providers,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoRouter _router;

  String _lastLoggedLocation = "";

  @override
  void initState() {
    super.initState();
    _router = router(sharedPreferences: context.read());
    _router.routerDelegate.addListener(() {
      final location = _router.state.matchedLocation;
      if (location != _lastLoggedLocation) {
        _lastLoggedLocation = location;
        // Report to analytics
        context.read<AnalyticsService>().logScreenView(location);
      }
    });

    unawaited(context.read<ResumeDemixing>().call());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

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
          valueListenable: context
              .read<SettingsRepository>()
              .themeModeNotifier,
          builder: (context, themeMode, child) => MaterialApp.router(
            title: "Musician's Toolbox",
            theme: lightTheme,
            darkTheme: darkTheme,
            routerConfig: _router,
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
