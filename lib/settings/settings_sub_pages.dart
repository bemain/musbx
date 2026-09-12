import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/repositories/song/song_settings_repository.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/drone/drone.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/settings/selectors.dart';
import 'package:musbx/settings/settings_page.dart';
import 'package:musbx/settings/slide_from_right_transition_page.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/custom_icons.dart';

SlideFromRightTransitionPage Function(BuildContext, GoRouterState)
settingsPageBuilder(Widget child) => (context, state) {
  return SlideFromRightTransitionPage(
    key: state.pageKey,
    child: child,
  );
};

class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage({
    super.key,
    this.title,
    required this.children,
  });

  final Widget? title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title,
      ),
      body: SettingsList(children: children),
    );
  }
}

class MetronomeSettingsPage extends StatelessWidget {
  const MetronomeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      title: Text("Metronome settings"),
      children: [
        SettingsGroup(
          children: [
            ValueListenableBuilder(
              valueListenable: Metronome.instance.showNotificationNotifier,
              builder: (context, showNotification, child) => ListTile(
                leading: Icon(Symbols.notification_settings),
                title: Text("Show notification"),
                subtitle: Text(
                  "Control the Metronome from the notifications drawer",
                ),
                onTap: () {
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
          ],
        ),
      ],
    );
  }
}

class SongsSettingsPage extends StatefulWidget {
  const SongsSettingsPage({super.key});

  @override
  State<SongsSettingsPage> createState() => _SongsSettingsPageState();
}

class _SongsSettingsPageState extends State<SongsSettingsPage> {
  late Future<int> _cacheSize = _measureCache();
  Future<int> _measureCache() =>
      FileCacheService.instance.scratch.directory("songs").size();
  void _refresh() => setState(() {
    _cacheSize = _measureCache();
  });

  final SongSettingsRepository songSettings = SongSettingsRepository.instance;

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      title: Text("Songs settings"),
      children: [
        SettingsGroup(
          children: [
            ValueListenableBuilder(
              valueListenable: songSettings.demixAutomaticallyNotifier,
              builder: (context, demixAutomatically, child) => ListTile(
                leading: Icon(Symbols.piano),
                title: Text("Split new songs"),
                subtitle: Text(
                  "Automatically split songs into instruments",
                ),
                onTap: () {
                  songSettings.demixAutomatically =
                      !songSettings.demixAutomatically;
                },
                trailing: Switch(
                  value: songSettings.demixAutomatically,
                  onChanged: (value) =>
                      songSettings.demixAutomatically = value,
                ),
              ),
            ),
          ],
        ),

        SettingsGroup(
          children: [
            ListenableBuilder(
              listenable: SongRepository.instance,
              builder: (context, child) => FutureBuilder<int>(
                future: _cacheSize,
                builder: (context, snapshot) {
                  final cacheSize = snapshot.data ?? 0;

                  return ListTile(
                    enabled:
                        SongRepository.instance.isNotEmpty && cacheSize > 0,
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

                        // Remove cache
                        for (final song in SongRepository.instance.getAll()) {
                          DemixingProcesses.cancel(song);
                        }
                        await FileCacheService.instance.scratch
                            .directory("songs")
                            .delete();

                        if (!mounted) return;
                        _refresh();
                      }
                    },
                  );
                },
              ),
            ),
            ListenableBuilder(
              listenable: SongRepository.instance,
              builder: (context, child) => ListTile(
                enabled: SongRepository.instance.isNotEmpty,
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

                    await SongRepository.instance.removeAll();
                    if (!mounted) return;
                    _refresh();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TunerSettingsPage extends StatelessWidget {
  const TunerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      title: Text("Tuner settings"),
      children: [
        SettingsGroup(
          children: [
            ValueListenableBuilder(
              valueListenable: Tuner.instance.tuningNotifier,
              builder: (context, tuning, child) => ListTile(
                leading: Icon(CustomIcons.tuning_fork),
                title: Text("Tuning"),
                subtitle: Text(
                  "${tuning.frequency.toStringAsFixed(0)} Hz",
                ),
                onTap: () async {
                  await showAlertSheet<void>(
                    context: context,
                    builder: (context) => TuningSelector(
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
                  await showAlertSheet<void>(
                    context: context,
                    builder: (context) => AccidentalSelector(
                      accidentalNotifier:
                          Tuner.instance.preferredAccidentalNotifier,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DroneSettingsPage extends StatelessWidget {
  const DroneSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      title: Text("Drone settings"),
      children: [
        SettingsGroup(
          children: [
            ValueListenableBuilder(
              valueListenable: Drone.instance.tuningNotifier,
              builder: (context, tuning, child) => ListTile(
                leading: Icon(CustomIcons.tuning_fork),
                title: Text("Tuning"),
                subtitle: Text(
                  "${tuning.frequency.toStringAsFixed(0)} Hz",
                ),
                onTap: () async {
                  await showAlertSheet<void>(
                    context: context,
                    builder: (context) => TuningSelector(
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
                  await showAlertSheet<void>(
                    context: context,
                    builder: (context) => TemperamentSelector(
                      temperamentNotifier: Drone.instance.temperamentNotifier,
                    ),
                  );
                },
              ),
            ),
            ValueListenableBuilder(
              valueListenable: Drone.instance.waveformNotifier,
              builder: (context, waveform, child) => ListTile(
                leading: Icon(WaveformShapeSelector.waveformIcon(waveform)),
                title: Text("Waveform shape"),
                subtitle: Text(
                  WaveformShapeSelector.waveformDescription(waveform),
                ),
                onTap: () async {
                  await showAlertSheet<void>(
                    context: context,
                    builder: (context) => WaveformShapeSelector(
                      waveformNotifier: Drone.instance.waveformNotifier,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
