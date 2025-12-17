import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/songs/demixer/demixing_process.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/songs/library_page/library_page.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';

class DemixingProgressIndicator extends StatefulWidget {
  const DemixingProgressIndicator({
    super.key,
    required this.song,
    this.onDemixingComplete,
  });

  final Song song;

  final void Function()? onDemixingComplete;

  @override
  State<DemixingProgressIndicator> createState() =>
      _DemixingProgressIndicatorState();
}

class _DemixingProgressIndicatorState
    extends State<DemixingProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.song.isDemixed,
      builder: (context, snapshot) {
        if (snapshot.data != false) {
          // Already demixed or loading
          return const SizedBox();
        }

        DemixingProcess? process = DemixingProcesses.get(widget.song);
        if (process == null) return _buildNotDemixed(context);

        return ListenableBuilder(
          listenable: process,
          builder: (context, child) {
            if (process.isCancelled || process.hasError) {
              return _buildNotDemixed(context);
            }

            if (process.isComplete) {
              widget.onDemixingComplete?.call();
            }

            return Tooltip(
              message:
                  "This song ${process.isActive ? "is being" : "has been"} split into instruments.",
              child: ValueListenableBuilder(
                valueListenable: process.progressNotifier,
                builder: (context, progress, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularLoadingCheck(
                        isComplete: process.isComplete,
                        progress: progress,
                      ),
                      if (!process.isComplete)
                        IconButton(
                          onPressed: () {
                            DemixingProcesses.cancel(widget.song);
                            setState(() {});
                          },
                          icon: const Icon(Symbols.piano),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotDemixed(BuildContext context) {
    return Tooltip(
      message: "This song has not been split into instruments.",
      child: IconButton(
        onPressed: () {
          DemixingProcesses.cancel(widget.song);
          DemixingProcesses.start(widget.song);
          setState(() {});
        },
        icon: const Icon(Symbols.piano_off),
      ),
    );
  }
}

class SongOptionsSheet extends StatefulWidget {
  const SongOptionsSheet({super.key, required this.song});

  final Song song;

  @override
  State<SongOptionsSheet> createState() => _SongOptionsSheetState();
}

class _SongOptionsSheetState extends State<SongOptionsSheet> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Songs.history,
      builder: (context, child) {
        // Any update to the history could be an update to *this* song.
        // Thus, we get the song from history each time we build instead of using
        // the song passed in the constructor.
        // For example, if the song is renamed while the sheet is open, it will
        // automatically be rebuilt with the correct information.
        final Song? song = Songs.history.entries.values
            .where((song) => song.id == widget.song.id)
            .firstOrNull;

        if (song == null) {
          return SizedBox();
        }

        return ListTileTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          minLeadingWidth: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ListTile(
                leading: LibraryPage.buildSongIcon(song),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                titleTextStyle: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                subtitle: Text(
                  song.artist ?? "Unknown artist",
                ),
                trailing: DemixingProgressIndicator(
                  song: song,
                  onDemixingComplete: () {
                    Future<void>.delayed(Duration(seconds: 3)).then<void>((_) {
                      // Trigger rebuild
                      if (context.mounted) setState(() {});
                    });
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Symbols.edit),
                title: const Text("Rename"),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    useRootNavigator: true,
                    builder: (context) {
                      final TextEditingController controller =
                          TextEditingController(text: song.title);

                      return AlertDialog(
                        title: const Text("Rename song"),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Enter title",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              if (controller.text.isNotEmpty) {
                                Songs.history.add(
                                  song.copyWith(
                                    title: controller.text,
                                  ),
                                );
                              }
                              Navigator.of(context).pop();
                            },
                            child: const Text("Rename"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                enabled: song.hasCache,
                leading: const Icon(Symbols.cloud_off),
                title: const Text("Clear cached files"),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    useRootNavigator: true,
                    builder: (context) {
                      return AlertDialog(
                        icon: const Icon(Symbols.cloud_off),
                        title: const Text("Clear cache?"),
                        content: const Text(
                          "This will free up some space on your device. Loading this song will take longer the next time.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          FilledButton(
                            onPressed: () {
                              song.clearCache();
                              song.shouldDemix = false;
                              Navigator.of(context).pop();
                              setState(() {});
                            },
                            child: const Text("Clear"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Symbols.delete),
                title: const Text("Remove from library"),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    useRootNavigator: true,
                    builder: (context) {
                      return AlertDialog(
                        icon: const Icon(Symbols.delete),
                        title: const Text("Remove song?"),
                        content: const Text(
                          "This will remove the song from your library.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          FilledButton(
                            onPressed: () {
                              Songs.history.remove(song);
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                            child: const Text("Remove"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
