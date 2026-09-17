import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/play_song.dart';
import 'package:musbx/domain/use_case/unload_song.dart';
import 'package:musbx/drone/drone_page.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/routing/routes.dart';
import 'package:musbx/routing/shell.dart';
import 'package:musbx/settings/settings_page.dart';
import 'package:musbx/settings/settings_sub_pages.dart';
import 'package:musbx/songs/library_page/library_page.dart';
import 'package:musbx/songs/song_page/song_page.dart';
import 'package:musbx/tuner/tuner_page.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/announcements_page.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// The key for the navigator used by the app.
///
/// This is used to show dialogs in places where no local context is available.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// The key for the navigator of the songs branch.
///
/// Used to close an open song from outside the widget tree, e.g. when it is
/// deleted.
final GlobalKey<NavigatorState> libraryNavigatorKey =
    GlobalKey<NavigatorState>();

/// The current [StatefulNavigationShell] used.
///
/// This is used to navigate to different branches of the app.
late StatefulNavigationShell navigationShell;

/// Build the app's router.
///
/// The four tools sit in branches of a [StatefulShellRoute], each keeping its
/// own navigation stack; the branch the user was last on is restored at launch.
/// Settings and announcements sit outside the shell, so they cover the
/// navigation bar.
GoRouter router({required SharedPreferencesService sharedPreferences}) {
  /// The current shell branch. This is persisted across app restarts.
  final PersistentValue<int> currentBranch = sharedPreferences.value(
    "currentBranch",
    initialValue: 1,
  );

  return GoRouter(
    navigatorKey: navigatorKey,
    restorationScopeId: "router",
    initialLocation: Routes.branches[currentBranch.value],
    routes: [
      GoRoute(
        path: "/",
        redirect: (context, state) => Routes.library,
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => SettingsPage(),
        routes: [
          GoRoute(
            path: Routes.metronome.replaceFirst("/", ""),
            pageBuilder: settingsPageBuilder(
              (context) => const MetronomeSettingsPage(),
            ),
          ),
          GoRoute(
            path: Routes.library.replaceFirst("/", ""),
            pageBuilder: settingsPageBuilder(
              (context) => const SongsSettingsPage(),
            ),
          ),
          GoRoute(
            path: Routes.tuner.replaceFirst("/", ""),
            pageBuilder: settingsPageBuilder(
              (context) => const TunerSettingsPage(),
            ),
          ),
          GoRoute(
            path: Routes.drone.replaceFirst("/", ""),
            pageBuilder: settingsPageBuilder(
              (context) => const DroneSettingsPage(),
            ),
          ),
          GoRoute(
            path: Routes.licenses.split("/").last,
            pageBuilder: settingsPageBuilder(
              (context) => LicensePage(
                applicationIcon: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: ImageIcon(
                    AssetImage("assets/splash/splash.png"),
                    size: 64.0,
                    color: Color(0xff0f58cf),
                  ),
                ),
                applicationVersion:
                    "Version ${context.read<PackageInfo>().version}",
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.announcements,
        builder: (context, state) => AnnouncementsPage(),
      ),

      StatefulShellRoute(
        builder: (context, state, shell) {
          navigationShell = shell;
          return Scaffold(
            body: shell,
            bottomNavigationBar: NavigationBar(
              onDestinationSelected: (index) {
                shell.goBranch(
                  index,
                  // When tapping the current tab, navigate to the initial location
                  initialLocation: index == shell.currentIndex,
                );
                currentBranch.value = index;
              },
              selectedIndex: shell.currentIndex,
              destinations: Routes.branches.map(_destination).toList(),
            ),
          );
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return ExtendedShellBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          ExtendedShellBranch(
            routes: [
              GoRoute(
                path: Routes.metronome,
                builder: (context, state) {
                  return const MetronomePage();
                },
              ),
            ],
          ),
          ExtendedShellBranch(
            navigatorKey: libraryNavigatorKey,
            routes: [
              GoRoute(
                path: Routes.library,
                builder: (context, state) {
                  // Dispose the previous player.
                  // This cannot be done in the song routes `onExit` callback,
                  // since that is called every time we switch tab.
                  WidgetsBinding.instance.addPostFrameCallback((
                    _,
                  ) async {
                    await context.read<UnloadSong>().call();
                  });

                  return LibraryPage();
                },
                routes: [
                  GoRoute(
                    path: ":id",
                    redirect: (context, state) {
                      final String id = state.pathParameters['id']!;
                      return context.read<SongRepository>().getById(id) == null
                          ? Routes.library
                          : null;
                    },
                    builder: (context, state) {
                      // TODO: Move this into SongPage
                      final String id = state.pathParameters['id']!;
                      final Song song = context.read<SongRepository>().getById(
                        id,
                      )!;

                      return FutureBuilder(
                        future: context
                            .read<PlaySong>()
                            .call(song)
                            .timeout(
                              const Duration(seconds: 30),
                              onTimeout: () => Result.failed(
                                TimeoutException(
                                  "Loading the song took too long",
                                ),
                              ),
                            ),
                        builder: (context, snapshot) {
                          Widget fail(Object error, Widget dialog) {
                            debugPrint("[Navigation] $error");
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) {
                                showExceptionDialog(dialog);
                                context.go(Routes.library);
                              },
                            );
                            return const SizedBox();
                          }

                          return switch (snapshot.data) {
                            null =>
                              SongPage(), // loading — SongPage already shimmers on song == null
                            Ok() => SongPage(),
                            AccessRestricted(:final error) => fail(
                              error,
                              const MusicPlayerAccessRestrictedDialog(),
                            ),
                            Failure(:final error) => fail(
                              error,
                              SongCouldNotBeLoadedDialog(error: error),
                            ),
                          };
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          ExtendedShellBranch(
            saveState: false,
            routes: [
              GoRoute(
                path: Routes.tuner,
                builder: (context, state) {
                  return const TunerPage();
                },
              ),
            ],
          ),
          ExtendedShellBranch(
            routes: [
              GoRoute(
                path: Routes.drone,
                builder: (context, state) {
                  return const DronePage();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// The navigation bar entry for a branch.
NavigationDestination _destination(String route) {
  switch (route) {
    case Routes.metronome:
      return NavigationDestination(
        label: "Metronome",
        icon: Icon(CustomIcons.metronome),
      );
    case Routes.library:
      return NavigationDestination(
        label: "Songs",
        icon: Icon(Symbols.library_music),
      );
    case Routes.tuner:
      return NavigationDestination(
        label: "Tuner",
        icon: Icon(Symbols.speed),
      );
    case Routes.drone:
      return NavigationDestination(
        label: "Drone",
        icon: Icon(CustomIcons.tuning_fork),
      );
    default:
      throw Exception("Unknown destination: $route");
  }
}
