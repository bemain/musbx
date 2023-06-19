import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer.dart';
import 'package:musbx/music_player/demixer/demixing_process.dart';
import 'package:musbx/music_player/demixer/stem.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';

class DemixerCard extends StatelessWidget {
  DemixerCard({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: musicPlayer.demixer.enabledNotifier,
        builder: (context, demixerEnabled, child) {
          return ValueListenableBuilder(
            valueListenable: musicPlayer.demixer.stateNotifier,
            builder: (context, state, child) {
              return Column(children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Switch(
                        value: demixerEnabled,
                        onChanged: musicPlayer.nullIfNoSongElse(
                          !musicPlayer.demixer.isReady
                              ? null
                              : (value) => musicPlayer.demixer.enabled = value,
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
                          onPressed: musicPlayer.nullIfNoSongElse(stems.every(
                                  (Stem stem) =>
                                      stem.enabled && stem.volume == 0.5)
                              ? null
                              : () {
                                  for (Stem stem in stems) {
                                    stem.volume = 0.5;
                                    stem.enabled = true;
                                  }
                                }),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                (musicPlayer.demixer.state == DemixerState.demixing)
                    ? buildLoading(context)
                    : musicPlayer.demixer.state == DemixerState.error
                        ? buildError()
                        : Column(children: [
                            for (Stem stem in musicPlayer.demixer.stems)
                              buildVolumeSlider(stem),
                          ]),
              ]);
            },
          );
        });
  }

  Widget buildLoading(BuildContext context) {
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
          if (musicPlayer.demixer.process != null)
            ValueListenableBuilder(
              valueListenable: musicPlayer.demixer.process!.stepNotifier,
              builder: (context, step, child) => buildLoadingText(context),
            ),
          if (musicPlayer.demixer.process != null)
            Align(
              alignment: const Alignment(0, 0.3),
              child: ValueListenableBuilder(
                valueListenable:
                    musicPlayer.demixer.process!.separationProgressNotifier,
                builder: (context, progress, child) =>
                    Text((progress == null) ? "" : "$progress%"),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildError() {
    return const SizedBox(
      height: 192,
      child: Center(
        child: Icon(Icons.cloud_off_rounded, size: 96),
      ),
    );
  }

  Widget buildLoadingTextWithInfoButton(
    BuildContext context,
    String title,
    String description,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Text(title),
        ),
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
          icon: const Icon(Icons.info_outline_rounded),
        )
      ],
    );
  }

  Widget buildLoadingText(BuildContext context) {
    switch (musicPlayer.demixer.process?.step) {
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
          "The server is demixing the song. \nAudio source separation is a complex process, and might take a while.",
        );
      case DemixingStep.downloading:
        return buildLoadingTextWithInfoButton(
          context,
          "Downloading...",
          "The song has been demixed and is being downloaded to your device.",
        );
      default:
        return const Text("Loading...");
    }
  }

  Widget buildVolumeSlider(Stem stem) {
    return ValueListenableBuilder(
      valueListenable: stem.enabledNotifier,
      builder: (context, stemEnabled, child) => Row(
        children: [
          Checkbox(
            value: stemEnabled,
            onChanged: musicPlayer.nullIfNoSongElse(
              (!musicPlayer.demixer.enabled)
                  ? null
                  : (bool? value) {
                      if (value != null) stem.enabled = value;
                    },
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(stem.type.name.toCapitalized()),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: stem.volumeNotifier,
              builder: (context, volume, child) => Slider(
                value: volume,
                onChanged: musicPlayer.nullIfNoSongElse(
                  (!musicPlayer.demixer.enabled || !stemEnabled)
                      ? null
                      : (double value) => stem.volume = value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
