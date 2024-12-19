import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/drone/drone_page.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/songs/library_page/library_page.dart';
import 'package:musbx/songs/player/music_player.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_source.dart';
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

  // TODO: Actually update this
  static final PersistentValue<String> currentRoute = PersistentValue(
    "currentRoute",
    initialValue: songsRoute,
  );

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    restorationScopeId: "router",
    initialLocation: currentRoute.value,
    routes: [
      StatefulShellRoute.indexedStack(
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
          StatefulShellBranch(routes: [
            GoRoute(
                path: songsRoute,
                builder: (context, state) {
                  MusicPlayer.instance.stop();

                  return LibraryPage();
                },
                routes: [
                  GoRoute(
                    path: ":id",
                    builder: (context, state) {
                      final MusicPlayer musicPlayer = MusicPlayer.instance;
                      final String? id = state.pathParameters["id"];

                      if (musicPlayer.song?.id != id) {
                        // Begin loading song
                        final Song? song = musicPlayer
                            .songHistory.history.values
                            .where((song) => song.id == id)
                            .firstOrNull;
                        if (song == null) {
                          throw GoException(
                              "There is no song with the given id: '$id'");
                        }

                        MusicPlayerState prevState = musicPlayer.state;
                        musicPlayer.loadSong(song).then(
                          (_) {},
                          onError: (error, _) {
                            debugPrint("[MUSIC PLAYER] $error");
                            showExceptionDialog(
                              song.source is YoutubeSource
                                  ? const YoutubeUnavailableDialog()
                                  : const FileCouldNotBeLoadedDialog(),
                            );
                            // Restore state
                            musicPlayer.stateNotifier.value = prevState;
                          },
                        );
                      }

                      return const SongPage();
                    },
                  ),
                ]),
          ]),
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
              )
            ],
          ),
        ],
      ),
    ],
  );

  static Scaffold _buildShell(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TODO: Remove bottom padding caused by SafeArea, which leaves a big space between the NavigationBar and the banner ad.
          NavigationBar(
            onDestinationSelected: (int index) {
              navigationShell.goBranch(
                index,
                // When tapping the current tab, navigate to the initial location
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            selectedIndex: navigationShell.currentIndex,
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
