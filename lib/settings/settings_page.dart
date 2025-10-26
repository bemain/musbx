import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/drone/drone.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/settings/selectors.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

/// A page with a slide-from-right transition.
CustomTransitionPage<void> settingsPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeIn)),
        ),
        child: child,
      );
    },
    child: child,
  );
}

class SettingsList extends StatelessWidget {
  /// Displays a list of [children] with formatting appropriate for a page in
  /// the settings menu.
  const SettingsList({
    super.key,
    required this.children,
  });

  /// The widgets to display in the list.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      data: ListTileThemeData(
        minTileHeight: 56,
        contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 24),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  /// Title for grouping a number of settings together.
  const SectionTitle({super.key, required this.text});

  /// Title describing the section.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 4),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: SettingsList(
        children: [
          SectionTitle(text: "Metronome"),
          ValueListenableBuilder(
            valueListenable: Metronome.instance.showNotificationNotifier,
            builder: (context, showNotification, child) => ListTile(
              leading: Icon(Symbols.notification_settings),
              title: Text("Show notification"),
              subtitle: Text(
                "Control the Metronome from the notifications drawer",
              ),
              onTap: () async {
                Metronome.instance.showNotification =
                    !Metronome.instance.showNotification;
              },
              trailing: Switch(
                value: Metronome.instance.showNotification,
                onChanged: (value) =>
                    Metronome.instance.showNotification = value,
              ),
            ),
          ),

          SectionTitle(text: "Songs"),
          ListenableBuilder(
            listenable: Songs.history,
            builder: (context, child) => ListTile(
              enabled:
                  Songs.history.entries.isNotEmpty &&
                  Songs.history.entries.values.every(
                    (song) => song.hasCache,
                  ),
              leading: Icon(Symbols.cloud_off),
              title: Text("Free up storage"),
              onTap: () async {
                final bool? shouldContinue = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      icon: Icon(Symbols.cloud_off),
                      title: Text("Clear cache?"),
                      content: Text(
                        "Offloading songs will free up some space on your device. Loading a song will take longer the next time.",
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text("Proceed"),
                        ),
                      ],
                    );
                  },
                );

                if (shouldContinue == true) {
                  // Make sure a song is not open
                  Navigation.navigationShell.goBranch(
                    Navigation.currentBranch.value,
                    initialLocation: true,
                  );

                  for (final song in Songs.history.entries.values.toList()) {
                    await song.clearCache();
                  }
                }
              },
            ),
          ),
          ListenableBuilder(
            listenable: Songs.history,
            builder: (context, child) => ListTile(
              enabled: Songs.history.entries.isNotEmpty,
              leading: Icon(Symbols.delete_sweep),
              title: Text("Remove all songs"),
              onTap: () async {
                final bool? shouldContinue = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      icon: Icon(Symbols.delete_sweep),
                      title: Text("Clear songs?"),
                      content: Text(
                        "Are you sure you want to remove all songs from your library?\n\nThis action cannot be undone.",
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text("Proceed"),
                        ),
                      ],
                    );
                  },
                );

                if (shouldContinue == true) {
                  // Make sure a song is not open
                  Navigation.navigationShell.goBranch(
                    Navigation.currentBranch.value,
                    initialLocation: true,
                  );

                  await Songs.history.clear();
                }
              },
            ),
          ),

          SectionTitle(text: "Tuner"),
          ValueListenableBuilder(
            valueListenable: Tuner.instance.tuningNotifier,
            builder: (context, tuning, child) => ListTile(
              leading: Icon(CustomIcons.tuning_fork),
              title: Text("Tuning"),
              subtitle: Text(
                "${tuning.frequency.toStringAsFixed(0)} Hz",
              ),
              onTap: () async {
                await _showModalBottomSheet<void>(
                  context,
                  TuningSelector(
                    tuningNotifier: Tuner.instance.tuningNotifier,
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: Tuner.instance.preferredAccidentalNotifier,
            builder: (context, accidental, child) => ListTile(
              leading: Icon(CustomIcons.accidentals),
              title: Text("Preferred accidentals"),
              subtitle: Text(
                AccidentalSelector.accidentalDescription(accidental),
              ),
              onTap: () async {
                await _showModalBottomSheet<void>(
                  context,
                  AccidentalSelector(
                    accidentalNotifier:
                        Tuner.instance.preferredAccidentalNotifier,
                  ),
                );
              },
            ),
          ),

          SectionTitle(text: "Drone"),
          ValueListenableBuilder(
            valueListenable: Drone.instance.tuningNotifier,
            builder: (context, tuning, child) => ListTile(
              leading: Icon(CustomIcons.tuning_fork),
              title: Text("Tuning"),
              subtitle: Text(
                "${tuning.frequency.toStringAsFixed(0)} Hz",
              ),
              onTap: () async {
                await _showModalBottomSheet<void>(
                  context,
                  TuningSelector(
                    tuningNotifier: Drone.instance.tuningNotifier,
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: Drone.instance.temperamentNotifier,
            builder: (context, temperament, child) => ListTile(
              leading: Icon(Symbols.tune),
              title: Text("Temperament"),
              subtitle: Text(
                TemperamentSelector.temperamentDescription(temperament),
              ),
              onTap: () async {
                await _showModalBottomSheet<void>(
                  context,
                  TemperamentSelector(
                    temperamentNotifier: Drone.instance.temperamentNotifier,
                  ),
                );
              },
            ),
          ),

          SectionTitle(text: "General"),
          ListTile(
            leading: Icon(Symbols.policy),
            title: Text("Privacy policy"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://bemain.github.io/musbx/privacy"));
            },
          ),
          ListTile(
            leading: Icon(Symbols.contract),
            title: Text("Licenses"),
            trailing: Icon(Symbols.chevron_forward),
            onTap: () {
              context.push(Routes.licenses);
            },
          ),
          if (!Purchases.hasPremium)
            ListTile(
              leading: Icon(Symbols.workspace_premium),
              title: Text("Upgrade to Premium"),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => const FreeAccessRestrictedDialog(),
                );
              },
            ),

          SectionTitle(text: "Contact"),
          ListTile(
            leading: Icon(Symbols.mail),
            title: Text("Mail"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("mailto:bemain.dev@gmail.com"));
            },
          ),
          ListTile(
            leading: Icon(Symbols.captive_portal),
            title: Text("Website"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://bemain.github.io"));
            },
          ),

          const SizedBox(height: 32),
          RichText(
            text: TextSpan(
              text: "Version ${LaunchHandler.info.version}\n",
              style: TextTheme.of(context).bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(0x50),
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Symbols.copyright,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(0x50),
                  ),
                ),
                TextSpan(text: " Benjamin Agardh ${DateTime.now().year}"),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<T?> _showModalBottomSheet<T>(BuildContext context, Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: false,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        );
      },
    );
  }
}
