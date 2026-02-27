import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/analytics.dart';
import 'package:musbx/drone/drone_page.dart';
import 'package:musbx/metronome/metronome_page.dart';
import 'package:musbx/settings/settings_page.dart';
import 'package:musbx/settings/settings_sub_pages.dart';
import 'package:musbx/songs/library_page/library_page.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/song_page/song_page.dart';
import 'package:musbx/tuner/tuner_page.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

class Routes {
  static const String metronome = "/metronome";
  static const String library = "/songs";
  static String song(String songId) => "$library/$songId";
  static const String tuner = "/tuner";
  static const String drone = "/drone";

  static const String settings = "/settings";
  static String get metronomeSettings => "$settings$metronome";
  static String get songsSettings => "$settings$library";
  static String get tunerSettings => "$settings$tuner";
  static String get droneSettings => "$settings$drone";

  static const String licenses = "/settings/licenses";
  static const String contact = "/settings/contact";

  /// The top-level shell branches.
  static const List<String> branches = [metronome, library, tuner, drone];
}

class Navigation {
  // The current shell branch. This is persisted across app restarts.
  static final PersistentValue<int> currentBranch = PersistentValue(
    "currentBranch",
    initialValue: 1,
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
                    const MetronomeSettingsPage(),
                  ),
                ),
                GoRoute(
                  path: Routes.library.replaceFirst("/", ""),
                  pageBuilder: settingsPageBuilder(
                    const SongsSettingsPage(),
                  ),
                ),
                GoRoute(
                  path: Routes.tuner.replaceFirst("/", ""),
                  pageBuilder: settingsPageBuilder(
                    const TunerSettingsPage(),
                  ),
                ),
                GoRoute(
                  path: Routes.drone.replaceFirst("/", ""),
                  pageBuilder: settingsPageBuilder(
                    const DroneSettingsPage(),
                  ),
                ),
                GoRoute(
                  path: Routes.licenses.split("/").last,
                  pageBuilder: settingsPageBuilder(
                    LicensePage(
                      applicationIcon: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: ImageIcon(
                          AssetImage("assets/splash/splash.png"),
                          size: 64.0,
                          color: Color(0xff0f58cf),
                        ),
                      ),
                      applicationVersion:
                          "Version ${LaunchHandler.info.version}",
                    ),
                  ),
                ),
              ],
            ),

            StatefulShellRoute(
              builder: _buildShell,
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
                              return Routes.library;
                            }

                            return null;
                          },
                          builder: (context, state) {
                            final String id = state.pathParameters['id']!;
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
                                    context.go(Routes.library);
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
        )
        ..routerDelegate.addListener(() {
          // Report to analytics
          Analytics.logScreenView(router.state.matchedLocation);
        });

  static Widget _buildShell(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell shell,
  ) {
    navigationShell = shell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: _buildNavigationBar(shell),
    );
  }

  static Widget _buildNavigationBar(StatefulNavigationShell shell) {
    NavigationDestination buildDestination(String route) {
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

    return NavigationBar(
      onDestinationSelected: (index) {
        shell.goBranch(
          index,
          // When tapping the current tab, navigate to the initial location
          initialLocation: index == shell.currentIndex,
        );
        currentBranch.value = index;
      },
      selectedIndex: shell.currentIndex,
      destinations: Routes.branches.map(buildDestination).toList(),
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
    return IndexedStack(
      index: currentIndex,
      children: [
        for (int i = 0; i < children.length; i++)
          _buildRouteBranchContainer(
            context,
            currentIndex == i,
            children[i],
          ),
      ],
    );
  }

  Widget _buildRouteBranchContainer(
    BuildContext context,
    bool isActive,
    Widget child,
  ) {
    final branch = (child as dynamic).branch as ExtendedShellBranch;

    if (!branch.saveState) {
      // For branches that don't save state, only render when active
      return isActive ? child : const SizedBox.shrink();
    }

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
