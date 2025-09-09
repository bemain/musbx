import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/analytics.dart';
import 'package:musbx/drone/drone_page.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/songs/library_page/library_page.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/song_page/song_page.dart';
import 'package:musbx/tuner/tuner_page.dart';
import 'package:musbx/utils/persistent_value.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/ads.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

class Navigation {
  static const String metronomeRoute = "/metronome";
  static const String songsRoute = "/songs";
  static String songRoute(String songId) => "$songsRoute/$songId";
  static const String tunerRoute = "/tuner";
  static const String droneRoute = "/drone";

  // The current route. This is persisted across app restarts.
  static final PersistentValue<String> currentRoute = PersistentValue(
    "currentRoute",
    initialValue: songsRoute,
  );

  /// The key for the navigator used by the app.
  ///
  /// This is used to show dialogs in places where no local context is available.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// The current [StatefulNavigationShell] used.
  ///
  /// This is used to navigate to different branches of the app.
  static late StatefulNavigationShell navigationShell;

  /// The router that handles navigation.
  static final GoRouter router =
      GoRouter(
          navigatorKey: navigatorKey,
          restorationScopeId: "router",
          initialLocation: currentRoute.value,
          routes: [
            GoRoute(
              path: "/",
              redirect: (context, state) => songsRoute,
            ),
            StatefulShellRoute(
              restorationScopeId: "shell",
              builder: _buildShell,
              navigatorContainerBuilder: (context, navigationShell, children) {
                return ExtendedShellBranchContainer(
                  currentIndex: navigationShell.currentIndex,
                  children: children,
                );
              },
              branches: [
                ExtendedShellBranch(
                  restorationScopeId: "metronome",
                  routes: [
                    GoRoute(
                      path: metronomeRoute,
                      builder: (context, state) {
                        return const MetronomePage();
                      },
                    ),
                  ],
                ),
                ExtendedShellBranch(
                  restorationScopeId: "songs",
                  routes: [
                    GoRoute(
                      path: songsRoute,
                      builder: (context, state) {
                        // Dispose the previous player.
                        // This cannot be done in the song routes `onExit` callback,
                        // since that is called every time we switch tab.
                        WidgetsBinding.instance.addPostFrameCallback((
                          _,
                        ) async {
                          await Songs.dispose();
                        });

                        return LibraryPage();
                      },
                      routes: [
                        GoRoute(
                          path: ":id",
                          redirect: (context, state) {
                            final String? id = state.pathParameters['id'];
                            if (Songs.history.entries.values
                                .where((song) => song.id == id)
                                .isEmpty) {
                              // If the song isn't in the library, redirect to the songs page
                              return songsRoute;
                            }

                            return null;
                          },
                          builder: (context, state) {
                            final String id = state.pathParameters['id']!;

                            // Begin loading song
                            final Song song = Songs.history.entries.values
                                .firstWhere((song) => song.id == id);

                            return FutureBuilder(
                              future:
                                  Songs.load(
                                    song,
                                    ignoreFreeLimit: song.id == demoSong.id,
                                  ).timeout(
                                    const Duration(seconds: 30),
                                  ),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  debugPrint(
                                    "[MUSIC PLAYER] ${snapshot.error}",
                                  );
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    showExceptionDialog(
                                      snapshot.error
                                              is AccessRestrictedException
                                          ? const MusicPlayerAccessRestrictedDialog()
                                          : const SongCouldNotBeLoadedDialog(),
                                    );
                                    context.go(songsRoute);
                                  });

                                  return const SizedBox();
                                }

                                return const SongPage();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                ExtendedShellBranch(
                  restorationScopeId: "tuner",
                  saveState: false,
                  routes: [
                    GoRoute(
                      path: tunerRoute,
                      builder: (context, state) {
                        return const TunerPage();
                      },
                    ),
                  ],
                ),
                ExtendedShellBranch(
                  restorationScopeId: "drone",
                  routes: [
                    GoRoute(
                      path: droneRoute,
                      builder: (context, state) {
                        return const DronePage();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        )
        ..routerDelegate.addListener(() {
          final String location = router.state.matchedLocation;
          // Report to analytics
          Analytics.logScreenView(location);

          // Update the current route. Only remember the top-level route, not which subroute we were on.
          currentRoute.value = "/${location.substring(1).split("/").first}";
        });

  static Widget _buildShell(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell shell,
  ) {
    navigationShell = shell;
    return ValueListenableBuilder(
      valueListenable: Purchases.hasPremiumNotifier,
      builder: (context, hasPremium, child) {
        return Scaffold(
          body: shell,
          bottomNavigationBar: hasPremium
              ? _buildNavigationBar(shell)
              : SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavigationBar(shell),
                      const BannerAdWidget(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  static Widget _buildNavigationBar(StatefulNavigationShell shell) {
    return NavigationBar(
      onDestinationSelected: (index) {
        shell.goBranch(
          index,
          // When tapping the current tab, navigate to the initial location
          initialLocation: index == shell.currentIndex,
        );
      },
      selectedIndex: shell.currentIndex,
      destinations: const [
        NavigationDestination(
          label: "Metronome",
          icon: Icon(CustomIcons.metronome),
        ),
        NavigationDestination(
          label: "Songs",
          icon: Icon(Symbols.library_music),
        ),
        NavigationDestination(
          label: "Tuner",
          icon: Icon(Symbols.speed),
        ),
        NavigationDestination(
          label: "Drone",
          icon: Icon(CustomIcons.tuning_fork),
        ),
      ],
    );
  }
}

class ExtendedShellBranchContainer extends StatelessWidget {
  const ExtendedShellBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> stackItems = [
      for (int i = 0; i < children.length; i++)
        _buildRouteBranchContainer(
          context,
          currentIndex == i,
          children[i],
        ),
    ];

    final child = children[currentIndex];
    final branch = (child as dynamic).branch as ExtendedShellBranch;

    return Stack(
      children: [
        IndexedStack(
          index: currentIndex,
          children: stackItems,
        ),
        if (!branch.saveState) children[currentIndex],
      ],
    );
  }

  Widget _buildRouteBranchContainer(
    BuildContext context,
    bool isActive,
    Widget child,
  ) {
    final branch = (child as dynamic).branch as ExtendedShellBranch;
    if (!branch.saveState) return const SizedBox.shrink();

    return Offstage(
      offstage: !isActive,
      child: TickerMode(
        enabled: isActive,
        child: child,
      ),
    );
  }
}

/// An extended `StatefulShellBranch` that adds the option to not save state.
/// See https://github.com/flutter/flutter/issues/142258.
class ExtendedShellBranch extends StatefulShellBranch {
  ExtendedShellBranch({
    this.saveState = true,
    super.initialLocation,
    super.navigatorKey,
    super.observers,
    super.restorationScopeId,
    required super.routes,
  });

  /// Whether to save the state for this branch.
  final bool saveState;
}
