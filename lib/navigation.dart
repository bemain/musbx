import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/drone/drone_page.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/songs/library_page/library_page.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/player/source.dart';
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
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    restorationScopeId: "router",
    initialLocation: currentRoute.value,
    routes: [
      StatefulShellRoute.indexedStack(
        restorationScopeId: "shell",
        builder: _buildShell,
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: metronomeRoute,
              builder: (context, state) {
                return const MetronomePage();
              },
            ),
          ]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: songsRoute,
                builder: (context, state) {
                  // Dispose the previous player.
                  // This cannot be done in the song routes `onExit` callback,
                  // since that is called every time we switch tab.
                  Songs.dispose();

                  return LibraryPage();
                },
                routes: [
                  GoRoute(
                    path: ":id",
                    redirect: (context, state) {
                      final String? id = state.pathParameters["id"];
                      if (Songs.history.map.values
                          .where((song) => song.id == id)
                          .isEmpty) {
                        // If the song isn't in the library, redirect to the songs page
                        return songsRoute;
                      }

                      return null;
                    },
                    builder: (context, state) {
                      final String id = state.pathParameters["id"]!;

                      // Begin loading song
                      final Song song = Songs.history.map.values
                          .firstWhere((song) => song.id == id);

                      return FutureBuilder(
                        future: Songs.load(song).timeout(
                          const Duration(seconds: 30),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            debugPrint("[MUSIC PLAYER] ${snapshot.error}");
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showExceptionDialog(
                                snapshot.error is AccessRestrictedException
                                    ? const MusicPlayerAccessRestrictedDialog()
                                    : song.source is YoutubeSource
                                        ? const YoutubeUnavailableDialog()
                                        : const FileCouldNotBeLoadedDialog(),
                              );
                              context.go(songsRoute);
                            });

                            return const SizedBox();
                          }

                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            // TODO: Build loading
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
          StatefulShellBranch(routes: [
            GoRoute(
              path: tunerRoute,
              builder: (context, state) {
                return const TunerPage();
              },
            ),
          ]),
          StatefulShellBranch(
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
  )..routerDelegate.addListener(() {
      // Update the current route whenever it changes
      currentRoute.value =
          router.routerDelegate.currentConfiguration.uri.toFilePath();
    });

  static Scaffold _buildShell(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell shell,
  ) {
    navigationShell = shell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO: Remove bottom padding caused by SafeArea, which leaves a big space between the NavigationBar and the banner ad.
          NavigationBar(
            onDestinationSelected: (int index) {
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
