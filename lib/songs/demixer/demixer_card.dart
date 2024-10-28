import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/demixer/demixing_process.dart';
import 'package:musbx/songs/demixer/stem.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/songs/player/music_player.dart';
import 'package:musbx/songs/player/song_source.dart';
import 'package:musbx/widgets/flat_card.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/widgets.dart';

class DemixerCard extends StatelessWidget {
  DemixerCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: musicPlayer.demixer.enabledNotifier,
        builder: (context, enabled, child) {
          return ValueListenableBuilder(
            valueListenable: musicPlayer.demixer.stateNotifier,
            builder: (context, state, child) {
              return FlatCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(children: [
                    _buildHeader(context),
                    SizedBox(
                      height: 288,
                      child: _buildBody(context),
                    ),
                  ]),
                ),
              );
            },
          );
        });
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: musicPlayer.demixer.enabled,
            onChanged: musicPlayer.nullIfNoSongElse(
              (musicPlayer.demixer.state == DemixerState.outOfDate ||
                      musicPlayer.demixer.state == DemixerState.error)
                  ? null
                  : (value) async {
                      if (value &&
                          musicPlayer.demixer.state != DemixerState.done &&
                          await isOnCellular()) {
                        // Show warning dialog
                        if (context.mounted) {
                          await showCellularWarningDialog(context);
                        }
                        return;
                      }

                      musicPlayer.demixer.enabled = value;
                    },
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Center(
            child: Text(
              "Demixer",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder(
            valueListenable: musicPlayer.demixer.stemsNotifier,
            builder: (context, stems, child) => IconButton(
              iconSize: 20,
              onPressed: musicPlayer.nullIfNoSongElse(
                stems.every((Stem stem) =>
                        stem.enabled && stem.volume == Stem.defaultVolume)
                    ? null
                    : () {
                        for (Stem stem in stems) {
                          stem.volume = Stem.defaultVolume;
                          stem.enabled = true;
                        }
                        musicPlayer.demixer.onStemsChanged();
                      },
              ),
              icon: const Icon(Symbols.refresh),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (musicPlayer.demixer.state) {
      case DemixerState.demixing:
        return buildLoading(context);

      case DemixerState.outOfDate:
        return buildOutOfDate();

      case DemixerState.error:
        return buildError();

      default:
        return ValueListenableBuilder(
          valueListenable: musicPlayer.demixer.stemsNotifier,
          builder: (context, stems, child) => Column(
            children: [
              for (Stem stem in musicPlayer.demixer.stems)
                StemControls(stem: stem),
            ],
          ),
        );
    }
  }

  Widget buildOutOfDate() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Icon(Symbols.update_rounded, size: 96),
        ),
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
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            """An error occurred while demixing. Please try again later.""",
            textAlign: TextAlign.center,
          ),
        ),
        OutlinedButton(
          onPressed: () {
            musicPlayer.demixer.enabled = false;
            musicPlayer.demixer.enabled = true;
          },
          child: const Text("Retry"),
        ),
      ],
    );
  }

  Widget buildLoading(BuildContext context) {
    if (musicPlayer.demixer.process == null) return const SizedBox(height: 192);

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
              valueListenable: musicPlayer.demixer.process!.stepNotifier,
              builder: (context, step, child) =>
                  Text("${step.index + 1} / ${DemixingStep.values.length}"),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: musicPlayer.demixer.process!.stepNotifier,
            builder: (context, step, child) => buildLoadingText(context),
          ),
          Align(
            alignment: const Alignment(0, 0.3),
            child: ValueListenableBuilder(
              valueListenable: musicPlayer.demixer.process!.progressNotifier,
              builder: (context, progress, child) => Text(
                  (progress == null) ? "" : "${(progress * 100).round()}%"),
            ),
          ),
        ],
      ),
    );
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

  Widget buildLoadingText(BuildContext context) {
    switch (musicPlayer.demixer.process?.step) {
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
          "The server is demixing the song. \nAudio source separation is a complex process, and might take a while. ${(musicPlayer.song?.source is YoutubeSource ? "\n\nYou may close the app while the demixing is in progress. \n\nThis only needs to be done once, so loading the song next time will be much faster." : "")}",
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
      case DemixingStep.extracting:
        return buildLoadingTextWithInfoButton(
          context,
          "Extracting...",
          "The compressed song downloaded from the server is being extracted. \n\nTo save space on your phone and decrease network traffic, all songs are compressed when they aren't being played.",
        );
      case null:
        return buildLoadingTextWithInfoButton(context, "Loading...");
    }
  }

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
              musicPlayer.demixer.enabled = true;
              Navigator.of(context).pop();
            },
            child: const Text("Enable"),
          ),
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
  MusicPlayer musicPlayer = MusicPlayer.instance;

  /// The volume of the stem.
  ///
  /// Note that this doesn't always equal [widget.stem.volume], as this value is
  /// changed whenever the user drags the volume slider but [widget.stem.volume]
  /// is only updated once the user is done selecting a value.
  late double volume = widget.stem.volume;

  /// Update [volume] to equal [widget.stem.volume]
  void updateVolume() {
    setState(() {
      volume = widget.stem.volume;
    });
  }

  @override
  void initState() {
    widget.stem.volumeNotifier.addListener(updateVolume);
    super.initState();
  }

  @override
  void dispose() {
    widget.stem.volumeNotifier.removeListener(updateVolume);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Whether all other stems are disabled
    final bool allOtherStemsDisabled = musicPlayer.demixer.stems
        .where((stem) => stem != widget.stem)
        .every((stem) => !stem.enabled);

    return Row(
      children: [
        GestureDetector(
          onLongPress:
              musicPlayer.nullIfNoSongElse((!musicPlayer.demixer.isReady)
                  ? null
                  : () {
                      if (!Purchases.hasPremium &&
                          musicPlayer.song?.id != demoSong.id) return;

                      for (Stem stem in musicPlayer.demixer.stems) {
                        stem.enabled = allOtherStemsDisabled;
                      }
                      widget.stem.enabled = !allOtherStemsDisabled;
                      musicPlayer.demixer.onStemsChanged();
                    }),
          child: IconButton(
              isSelected: widget.stem.enabled,
              onPressed: musicPlayer.nullIfNoSongElse(
                (!musicPlayer.demixer.isReady)
                    ? null
                    : () {
                        if (allOtherStemsDisabled) return;

                        if (!Purchases.hasPremium &&
                            musicPlayer.song?.id != demoSong.id &&
                            widget.stem.type != StemType.vocals) {
                          showAccessRestrictedDialog(context);
                          return;
                        }

                        widget.stem.enabled = !widget.stem.enabled;
                        musicPlayer.demixer.onStemsChanged();
                      },
              ),
              icon: Icon(getStemIcon(widget.stem.type))),
        ),
        Expanded(
          child: Slider(
            value: volume,
            onChanged: musicPlayer.nullIfNoSongElse(
              (!musicPlayer.demixer.isReady || !widget.stem.enabled)
                  ? null
                  : (double value) {
                      if (!Purchases.hasPremium &&
                          musicPlayer.song?.id != demoSong.id &&
                          widget.stem.type != StemType.vocals) {
                        showAccessRestrictedDialog(context);
                        return;
                      }

                      setState(() {
                        volume = value;
                      });
                    },
            ),
            onChangeEnd: (value) {
              if (!Purchases.hasPremium &&
                  musicPlayer.song?.id != demoSong.id &&
                  widget.stem.type != StemType.vocals) {
                return;
              }
              widget.stem.volume = value;
              musicPlayer.demixer.onStemsChanged();
            },
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
