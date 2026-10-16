import 'package:flutter/material.dart';
import 'package:flutter_m3shapes/flutter_m3shapes.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/demix/demixing_process.dart';
import 'package:musbx/data/repositories/entitlement/entitlement_repository.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/services/musbx_api/musbx_api.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/domain/use_case/load_song.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/widgets/flat_card.dart';
import 'package:musbx/widgets/result_builder.dart';
import 'package:provider/provider.dart';

/// Follows the demixing of the loaded song, and offers to start, cancel or retry
/// it.
class DemixingProcessIndicator extends StatefulWidget {
  const DemixingProcessIndicator({super.key});

  @override
  State<DemixingProcessIndicator> createState() =>
      _DemixingProcessIndicatorState();
}

class _DemixingProcessIndicatorState extends State<DemixingProcessIndicator> {
  DemixRepository get demixing => context.read();
  PlaybackRepository get playback => context.read();
  SongPreferencesRepository get preferences => context.read();
  SettingsRepository get settings => context.read();

  Future<void> _setDemix(Song song, bool value) async {
    final prefs = (await preferences.read(song)).asOk;
    (await preferences.write(
      song,
      (prefs ?? SongPreferences()).copyWith(shouldDemix: value),
    )).asOk;
  }

  /// The song [_process] was started for.
  Song? _processSong;

  /// The result of [_startDemixing] for [_processSong].
  ///
  /// Kept across builds, which the player triggers on every change to
  /// playback, so that the card does not reload each time. Cleared to start
  /// over.
  Future<Result<DemixingProcess?>>? _process;

  Future<Result<DemixingProcess?>> _processFor(Song song) {
    if (_process case final process? when song == _processSong) return process;
    _processSong = song;
    return _process = _startDemixing(song);
  }

  /// The process demixing [song], or `null` if demixing it is disabled.
  ///
  /// Starting the process notifies [DemixRepository]'s listeners, so this must
  /// not run during build.
  Future<Result<DemixingProcess?>> _startDemixing(Song song) async {
    try {
      final prefs = (await preferences.read(song)).asOk;
      final demix = prefs?.shouldDemix ?? settings.songs.demixAutomatically;
      if (!demix) return Result.ok(null);

      return Result.ok(demixing.start(song).asOk);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = playback.song;
    if (song == null) return buildDemixDisabled();

    return ResultBuilder(
      future: _processFor(song),
      ok: (context, process) {
        if (process == null) return buildDemixDisabled();

        return ListenableBuilder(
          listenable: process,
          builder: (context, child) {
            if (process.hasError) {
              if (process.error is OutOfDate) return buildOutOfDate();

              return buildError();
            }

            return Column(
              children: [
                Expanded(child: SizedBox()),
                buildCookie(
                  child: ValueListenableBuilder(
                    valueListenable: process.progressNotifier,
                    builder: (context, progress, child) =>
                        CircularLoadingCheck(
                          progress: progress,
                          isComplete: !process.isRunning,
                          size: 96,
                        ),
                  ),
                ),

                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: Center(
                    child: ValueListenableBuilder(
                      valueListenable: process.stepNotifier,
                      builder: (context, step, child) =>
                          buildLoadingText(context, process),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                process.isRunning
                    ? TextButton(
                        onPressed: () async {
                          demixing.cancel(song);
                          await _setDemix(song, false);
                          if (mounted) setState(() => _process = null);
                        },
                        child: const Text("Cancel"),
                      )
                    : FilledButton(
                        // Reloads in place: navigating to the same route keeps
                        // this page's state, so it would not load again.
                        onPressed: () async {
                          if (await context.read<LoadSong>().call(song)
                              case Failure(:final error)) {
                            await showExceptionDialog(
                              SongCouldNotBeLoadedDialog(error: error),
                            );
                          }
                        },
                        child: const Text("Reload"),
                      ),
                Expanded(child: SizedBox()),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildCookie({required Widget child}) {
    return M3Container.c9SidedCookie(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(padding: EdgeInsets.all(32), child: child),
    );
  }

  Widget buildInfo(Widget icon, List<Widget> children) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        buildCookie(child: icon),
        ...children,
      ],
    );
  }

  Widget buildDemixDisabled() {
    return buildInfo(
      Icon(Symbols.disabled_by_default, size: 96),
      [
        const Text(
          """Automatically splitting songs into instruments is currently disabled in the settings.""",
          textAlign: TextAlign.center,
        ),
        OutlinedButton(
          onPressed: () async {
            final song = playback.song;
            if (song == null) return;

            await _setDemix(song, true);
            if (mounted) setState(() => _process = null);
          },
          child: const Text("Continue anyway"),
        ),
      ],
    );
  }

  Widget buildOutOfDate() {
    return buildInfo(
      Icon(Symbols.update_rounded, size: 96),
      [
        const Text(
          """A newer version of the app is available. 
Please update to the latest version to use the Demixer.""",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildError() {
    return buildInfo(Icon(Symbols.error_rounded, size: 96), [
      const Text(
        """An error occurred while the song was being split into instruments. Please try again.""",
        textAlign: TextAlign.center,
      ),
      OutlinedButton(
        onPressed: () {
          final song = playback.song;
          if (song == null) return;

          // The next build starts a new process in place of the failed one.
          demixing.cancel(song);
          setState(() => _process = null);
        },
        child: const Text("Retry"),
      ),
    ]);
  }

  Widget buildLoadingText(BuildContext context, DemixingProcess process) {
    if (!process.isRunning) {
      return const Text(
        "The song has been split into instruments. To complete the loading process, reload the page.",
        textAlign: TextAlign.center,
      );
    }

    switch (process.step) {
      case DemixingStep.findingHost:
        return buildLoadingTextWithInfoButton(context, "Preparing...");
      case DemixingStep.uploading:
        return buildLoadingTextWithInfoButton(
          context,
          "Uploading...",
          "The song is being uploaded to the server, and will soon be queued for splitting.",
        );
      case DemixingStep.separating:
        return buildLoadingTextWithInfoButton(
          context,
          "Splitting...",
          """The server is splitting the song into instruments. 
Audio source separation is a complex process, and might take a while. 

You may close the app while the demixing is in progress. 

This only needs to be done once, so loading the song next time will be much faster.""",
        );
      case DemixingStep.compressing:
        return buildLoadingTextWithInfoButton(
          context,
          "Compressing...",
          "The server is compressing the song to decrease the amount of data that needs to be sent.",
        );
      case DemixingStep.downloading:
        return buildLoadingTextWithInfoButton(
          context,
          "Downloading...",
          "The song has been split into instruments and is being downloaded to your device.",
        );
    }
  }

  Widget buildLoadingTextWithInfoButton(
    BuildContext context,
    String title, [
    String? description,
  ]) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.clip,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: title),
          if (description != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: IconButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(title),
                        content: Text(description),
                      );
                    },
                  );
                },
                icon: const Icon(Symbols.info),
              ),
            ),
        ],
      ),
    );
  }
}

/// The part controls for the loaded song, or the demixing progress while its
/// parts are still being separated.
class DemixerCard extends StatelessWidget {
  const DemixerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final PlaybackRepository playback = context.read();

    if (playback.song == null) {
      return ShimmerLoading(
        child: FlatCard(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: const SizedBox.expand(),
        ),
      );
    }

    return FlatCard(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
        child: () {
          if (!playback.isMulti) {
            return DemixingProcessIndicator();
          }

          return Column(
            children: [
              buildHeader(context),
              Expanded(
                child: buildBody(context),
              ),
              SizedBox(height: 8),
            ],
          );
        }(),
      ),
    );
  }

  /// The button resetting every part, shown above the part controls.
  Widget buildHeader(BuildContext context) {
    final PlaybackRepository playback = context.read();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ListenableBuilder(
          listenable: playback,
          builder: (context, child) => IconButton(
            iconSize: 20,
            onPressed:
                playback.parts?.every(
                      (part) =>
                          playback.getPartEnabled(part) == true &&
                          playback.getPartVolume(part) ==
                              PlaybackRepository.partDefaultVolume,
                    ) ??
                    true
                ? null
                : () {
                    for (Part part in playback.parts ?? []) {
                      playback.setPart(
                        part,
                        enabled: true,
                        volume: PlaybackRepository.partDefaultVolume,
                      );
                    }
                  },
            icon: const Icon(Symbols.refresh),
          ),
        ),
      ],
    );
  }

  /// The controls for each part of the loaded song.
  Widget buildBody(BuildContext context) {
    final PlaybackRepository playback = context.read();

    return ListenableBuilder(
      listenable: playback,
      builder: (context, child) {
        return Column(
          children: [
            for (Part part in playback.parts ?? []) PartControls(part: part),
          ],
        );
      },
    );
  }
}

/// Widget for enabling/disabling and changing the volume of a demixer [part].
class PartControls extends StatefulWidget {
  const PartControls({super.key, required this.part});

  /// The part this widget controls.
  final Part part;

  @override
  State<StatefulWidget> createState() => PartControlsState();
}

class PartControlsState extends State<PartControls> {
  PlaybackRepository get playback => context.read();
  EntitlementRepository get entitlement => context.read();

  Part get part => widget.part;

  @override
  Widget build(BuildContext context) {
    if (!playback.isMulti) return const SizedBox();

    /// Whether this part is allowed to be accessed.
    final bool accessAllowed =
        entitlement.hasPremium ||
        playback.song?.id == demoSong.id ||
        PlaybackRepository.freeParts.contains(part);

    /// Whether all other parts are disabled
    final bool allOtherPartsDisabled =
        playback.parts
            ?.where((part) => part != this.part)
            .every((part) => playback.getPartEnabled(part) ?? false) ??
        false;

    return ListenableBuilder(
      listenable: playback,
      builder: (context, child) {
        final bool enabled = playback.getPartEnabled(part) ?? true;
        final double volume =
            playback.getPartVolume(part) ??
            PlaybackRepository.partDefaultVolume;
        return Row(
          children: [
            SizedBox(width: 12),
            GestureDetector(
              onLongPress: () {
                if (!entitlement.hasPremium &&
                    playback.song?.id != demoSong.id) {
                  return;
                }

                for (Part part in playback.parts ?? []) {
                  playback.setPart(part, enabled: allOtherPartsDisabled);
                }
                playback.setPart(part, enabled: !allOtherPartsDisabled);
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  IconButton.filledTonal(
                    isSelected: enabled && volume != 0,
                    onPressed: () {
                      if (!accessAllowed) {
                        showAccessRestrictedDialog(context);
                        return;
                      }

                      if (volume == 0) {
                        playback.setPart(
                          part,
                          enabled: true,
                          volume: PlaybackRepository.partDefaultVolume,
                        );
                      } else {
                        playback.setPart(part, enabled: !enabled);
                      }
                    },
                    icon: Icon(getPartIcon(part)),
                  ),
                  if (!accessAllowed)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          onPressed: () {
                            showAccessRestrictedDialog(context);
                          },
                          icon: Icon(Symbols.lock),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Slider(
                min: 0.0,
                max: 2.0,
                value: !enabled ? 0 : volume,
                onChangeStart: (value) {
                  if (!accessAllowed) {
                    showAccessRestrictedDialog(context);
                    return;
                  }

                  playback.setPart(part, enabled: true);
                },
                onChanged: (value) {
                  if (!accessAllowed) return;
                  playback.setPart(part, volume: value);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  IconData getPartIcon(Part part) {
    return switch (part) {
      Part.vocals => CustomIcons.microphone,
      Part.piano => Symbols.piano,
      Part.guitar => CustomIcons.guitar_head,
      Part.bass => CustomIcons.bass_head,
      Part.drums => CustomIcons.snare,
      Part.other => Symbols.music_note,
    };
  }

  Future<void> showAccessRestrictedDialog(BuildContext context) async {
    await showExceptionDialog(
      const FreeAccessRestrictedDialog(
        reason:
            "The full capabilities of the Demixer are not available on the Free version of the app.",
      ),
    );
  }
}
