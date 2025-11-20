import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/demixer/demixing_process.dart';
import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/utils/loading.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/widgets/flat_card.dart';
import 'package:musbx/widgets/loading_checkmark.dart';

class DemixingProcessIndicator extends StatefulWidget {
  const DemixingProcessIndicator({super.key, required this.player});

  final SinglePlayer player;

  Song get song => player.song;

  @override
  State<DemixingProcessIndicator> createState() =>
      _DemixingProcessIndicatorState();
}

class _DemixingProcessIndicatorState extends State<DemixingProcessIndicator> {
  DemixingProcess get process => widget.player.demixingProcess;

  bool get demix => widget.player.demix ?? Songs.demixAutomatically;

  @override
  Widget build(BuildContext context) {
    if (!demix) {
      return buildDemixDisabled();
    }

    return ListenableBuilder(
      listenable: process,
      builder: (context, child) {
        if (process.hasError) {
          if (process.error is OutOfDateException) return buildOutOfDate();

          return buildError();
        }

        if (!process.isActive) {
          /// Override the history entry for the song with a demixed variant.
          Songs.history.add(
            widget.song.withSource<MultiPlayable>(
              DemixedSource(widget.song.source),
            ),
          );
        }

        return Column(
          children: [
            Text(
              "Instruments",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(child: SizedBox()),
            ValueListenableBuilder(
              valueListenable: process.progressNotifier,
              builder: (context, progress, child) => CircularLoadingCheck(
                progress: progress,
                isComplete: !process.isActive,
                size: 96,
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
            process.isActive
                ? TextButton(
                    onPressed: () {
                      setState(() {
                        widget.player.demix = false;
                      });
                    },
                    child: Text("Cancel"),
                  )
                : FilledButton(
                    onPressed: () {
                      context.replace(Routes.song(widget.song.id));
                    },
                    child: Text("Reload"),
                  ),
            Expanded(child: SizedBox()),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget buildDemixDisabled() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Symbols.disabled_by_default, size: 96),
        const SizedBox(height: 8),
        const Text(
          """Automatically splitting songs into instruments is currently disabled in the settings.""",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            setState(() {
              widget.player.demix = true;
            });
          },
          child: const Text("Continue anyway"),
        ),
      ],
    );
  }

  Widget buildOutOfDate() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Symbols.update_rounded, size: 96),
        SizedBox(height: 8),
        Text(
          """A newer version of the app is available. 
Please update to the latest version to use the Demixer.""",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Symbols.cloud_off_rounded, size: 96),
        const SizedBox(height: 8),
        const Text(
          """An error occurred while the song was being split into instruments. Please try again.""",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            setState(() {
              widget.player.restartDemixing();
            });
          },
          child: const Text("Retry"),
        ),
      ],
    );
  }

  Widget buildLoadingText(BuildContext context, DemixingProcess process) {
    if (!process.isActive) {
      return const Text(
        "The song has been split into instruments. To complete the loading process, reload the page.",
        textAlign: TextAlign.center,
      );
    }

    switch (process.step) {
      case DemixingStep.checkingCache:
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

class DemixerCard extends StatelessWidget {
  const DemixerCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (Songs.player == null) {
      return ShimmerLoading(
        child: FlatCard(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: const SizedBox.expand(),
        ),
      );
    }

    final SongPlayer player = Songs.player!;

    return FlatCard(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
        child: () {
          if (player is SinglePlayer) {
            return DemixingProcessIndicator(player: player);
          }

          return Column(
            children: [
              buildHeader(context),
              Expanded(
                child: buildBody(context),
              ),
            ],
          );
        }(),
      ),
    );
  }

  /// Assumes [Songs.player] is a [MultiPlayer].
  Widget buildHeader(BuildContext context) {
    final MultiPlayer player = Songs.player! as MultiPlayer;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: Center(
            child: Text(
              "Instruments",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder(
            valueListenable: player.demixer.stemsNotifier,
            builder: (context, stems, child) => IconButton(
              iconSize: 20,
              onPressed:
                  stems.every(
                    (stem) =>
                        stem.enabled && stem.volume == Stem.defaultVolume,
                  )
                  ? null
                  : () {
                      for (Stem stem in stems) {
                        stem.volume = Stem.defaultVolume;
                        stem.enabled = true;
                      }
                    },
              icon: const Icon(Symbols.refresh),
            ),
          ),
        ),
      ],
    );
  }

  /// Assumes [Songs.player] is a [MultiPlayer].
  Widget buildBody(BuildContext context) {
    final MultiPlayer player = Songs.player! as MultiPlayer;

    return ValueListenableBuilder(
      valueListenable: player.demixer.stemsNotifier,
      builder: (context, stems, child) => ListView(
        children: [
          for (Stem stem in player.demixer.stems) StemControls(stem: stem),
        ],
      ),
    );
  }
}

class StemControls extends StatefulWidget {
  /// Widget for enabling/disabling and changing the volume of [stem].
  const StemControls({super.key, required this.stem});

  @override
  State<StatefulWidget> createState() => StemControlsState();

  /// The stem this widget controls.
  final Stem stem;
}

class StemControlsState extends State<StemControls> {
  SongPlayer player = Songs.player!;

  @override
  Widget build(BuildContext context) {
    if (this.player is! MultiPlayer) return const SizedBox();
    final MultiPlayer player = this.player as MultiPlayer;

    /// Whether all other stems are disabled
    final bool allOtherStemsDisabled = player.demixer.stems
        .where((stem) => stem != widget.stem)
        .every((stem) => !stem.enabled);

    return Row(
      children: [
        GestureDetector(
          onLongPress: () {
            if (!Purchases.hasPremium && player.song.id != demoSong.id) {
              return;
            }

            for (Stem stem in player.demixer.stems) {
              stem.enabled = allOtherStemsDisabled;
            }
            widget.stem.enabled = !allOtherStemsDisabled;
          },
          child: IconButton(
            isSelected: widget.stem.enabled,
            onPressed: () {
              if (allOtherStemsDisabled) return;

              if (!Purchases.hasPremium &&
                  player.song.id != demoSong.id &&
                  widget.stem.type != StemType.vocals) {
                showAccessRestrictedDialog(context);
                return;
              }

              widget.stem.enabled = !widget.stem.enabled;
            },
            icon: Icon(getStemIcon(widget.stem.type)),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: widget.stem.volumeNotifier,
            builder: (context, volume, child) => Slider(
              value: volume,
              onChanged: (!widget.stem.enabled)
                  ? null
                  : (value) {
                      if (!Purchases.hasPremium &&
                          player.song.id != demoSong.id &&
                          widget.stem.type != StemType.vocals) {
                        showAccessRestrictedDialog(context);
                        return;
                      }

                      widget.stem.volume = value;
                    },
            ),
          ),
        ),
      ],
    );
  }

  IconData getStemIcon(StemType stem) {
    return switch (stem) {
      StemType.vocals => CustomIcons.microphone,
      StemType.piano => Symbols.piano,
      StemType.guitar => CustomIcons.guitar_head,
      StemType.bass => CustomIcons.bass_head,
      StemType.drums => CustomIcons.snare,
      StemType.other => Symbols.music_note,
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
