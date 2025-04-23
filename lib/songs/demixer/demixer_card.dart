import 'dart:io';

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
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/widgets/flat_card.dart';
import 'package:musbx/utils/purchases.dart';

class DemixingProcessIndicator extends StatefulWidget {
  const DemixingProcessIndicator({super.key, required this.song});

  final Song song;

  @override
  State<DemixingProcessIndicator> createState() =>
      _DemixingProcessIndicatorState();
}

class _DemixingProcessIndicatorState extends State<DemixingProcessIndicator> {
  late DemixingProcess process;

  @override
  void initState() {
    super.initState();
    process = createProcess();
  }

  @override
  void dispose() {
    process.cancel();
    super.dispose();
  }

  DemixingProcess createProcess() {
    return DemixingProcess(
      widget.song.source,
      cacheDirectory: Directory("${widget.song.cacheDirectory.path}/source/"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: process,
      builder: (context, child) {
        if (process.hasError) {
          if (process.error is OutOfDateException) return buildOutOfDate();

          return buildError();
        }

        if (process.isActive) {
          return buildLoading(context, process);
        }

        /// Override the history entry for the song with a demixed variant.
        Songs.history.add(widget.song.copyWith<MultiPlayable>(
          source: DemixedSource(widget.song.source),
        ));

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.check_circle_rounded, size: 96),
            const SizedBox(height: 8),
            const Text(
              "The song has been separated into instruments. To complete the loading process, reload the page.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                context.replace(Navigation.songRoute(widget.song.id));
              },
              child: const Text("Reload"),
            ),
          ],
        );
      },
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
          """An error occurred while demixing. Please try again later.""",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            setState(() {
              process = createProcess();
            });
          },
          child: const Text("Retry"),
        ),
      ],
    );
  }

  Widget buildLoading(BuildContext context, DemixingProcess process) {
    // TODO: Add "Cancel" button
    return SizedBox(
      height: 192,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.3),
            child: ValueListenableBuilder(
              valueListenable: process.stepNotifier,
              builder: (context, step, child) =>
                  Text("${step.index} / ${DemixingStep.values.length - 1}"),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: process.stepNotifier,
            builder: (context, step, child) =>
                buildLoadingText(context, process),
          ),
          Align(
            alignment: const Alignment(0, 0.3),
            child: ValueListenableBuilder(
              valueListenable: process.progressNotifier,
              builder: (context, progress, child) => Text(
                  (progress == null) ? "" : "${(progress * 100).round()}%"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingText(BuildContext context, DemixingProcess process) {
    switch (process.step) {
      case DemixingStep.checkingCache:
      case DemixingStep.findingHost:
        return buildLoadingTextWithInfoButton(context, "Preparing...");
      case DemixingStep.uploading:
        return buildLoadingTextWithInfoButton(
          context,
          "Uploading...",
          "The song is being uploaded to the server, and will soon be queued for demixing.",
        );
      case DemixingStep.separating:
        return buildLoadingTextWithInfoButton(
          context,
          "Demixing...",
          "The server is demixing the song. \nAudio source separation is a complex process, and might take a while. ${(widget.song.source is YoutubeSource ? "\n\nYou may close the app while the demixing is in progress. \n\nThis only needs to be done once, so loading the song next time will be much faster." : "")}",
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
          "The song has been demixed and is being downloaded to your device.",
        );
    }
  }

  Widget buildLoadingTextWithInfoButton(
    BuildContext context,
    String title, [
    String? description,
  ]) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: (description == null) ? 256 : 160),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
        if (description != null)
          IconButton(
            onPressed: () {
              showDialog(
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
          )
      ],
    );
  }

  /// TODO: Remove? Leaving it here for the moment since I might want to use it later
  Future<void> showCellularWarningDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enable Demixer on cellular?"),
        content: const Text(
            "Your device is connected to a mobile network. Please note that the Demixer requires downloading some data (around 50 MB per song). Are you sure you want to enable the Demixer using cellular?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // player.demixer.enabled = true;
              Navigator.of(context).pop();
            },
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }
}

class DemixerCard extends StatelessWidget {
  DemixerCard({super.key});

  final SongPlayer player = Songs.player!;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      child: Padding(
          padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
          child: () {
            if (player is! MultiPlayer) {
              return DemixingProcessIndicator(song: player.song);
            }
            return Column(children: [
              buildHeader(context),
              Expanded(
                child: buildBody(context),
              ),
            ]);
          }()),
    );
  }

  /// Assumes [player] is a [MultiPlayer].
  Widget buildHeader(BuildContext context) {
    final MultiPlayer player = this.player as MultiPlayer;

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
              onPressed: stems.every((Stem stem) =>
                      stem.enabled && stem.volume == Stem.defaultVolume)
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

  /// Assumes [player] is a [MultiPlayer].
  Widget buildBody(BuildContext context) {
    final MultiPlayer player = this.player as MultiPlayer;

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
              icon: Icon(getStemIcon(widget.stem.type))),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: widget.stem.volumeNotifier,
            builder: (context, volume, child) => Slider(
              value: volume,
              onChanged: (!widget.stem.enabled)
                  ? null
                  : (double value) {
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
