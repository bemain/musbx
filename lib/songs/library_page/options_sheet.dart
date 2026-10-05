import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/demix/demixing_process.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/clear_song_cache.dart';
import 'package:musbx/songs/library_page/song_tile.dart';
import 'package:musbx/utils/result.dart';
import 'package:provider/provider.dart';

/// Follows the demixing of [song], showing which step it is on and how far it
/// has come.
///
/// Offers to start demixing when nothing is running, and to cancel or retry once
/// something is.
class DemixingProgressIndicator extends StatefulWidget {
  const DemixingProgressIndicator({
    super.key,
    required this.song,
    this.onDemixingComplete,
  });

  final Song song;

  /// Called once the stems are ready.
  final void Function()? onDemixingComplete;

  @override
  State<DemixingProgressIndicator> createState() =>
      _DemixingProgressIndicatorState();
}

class _DemixingProgressIndicatorState
    extends State<DemixingProgressIndicator> {
  DemixRepository get demix => context.read();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: demix.hasStems(widget.song),
      builder: (context, snapshot) {
        if (snapshot.data != false) {
          // Already demixed or loading
          return const SizedBox();
        }

        DemixingProcess? process = demix.get(
          widget.song,
        );
        if (process == null) return _buildNotDemixed(context);

        return ListenableBuilder(
          listenable: process,
          builder: (context, child) {
            if (process.isCancelled || process.hasError) {
              return _buildNotDemixed(context);
            }

            if (!process.isRunning) {
              widget.onDemixingComplete?.call();
            }

            return Tooltip(
              message:
                  "This song ${process.isRunning ? "is being" : "has been"} split into instruments.",
              child: ValueListenableBuilder(
                valueListenable: process.progressNotifier,
                builder: (context, progress, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularLoadingCheck(
                        isComplete: !process.isRunning,
                        progress: progress,
                      ),
                      if (process.isRunning)
                        IconButton(
                          onPressed: () {
                            demix.cancel(widget.song);
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
          demix.cancel(widget.song);
          demix.start(widget.song);
          setState(() {});
        },
        icon: const Icon(Symbols.piano_off),
      ),
    );
  }
}

/// A bottom sheet for one song: what it takes up on disk, whether it is demixed,
/// and the options to clear its cache or delete it.
class SongOptionsSheet extends StatefulWidget {
  const SongOptionsSheet({super.key, required this.song});

  /// The song these options apply to.
  final Song song;

  @override
  State<SongOptionsSheet> createState() => _SongOptionsSheetState();
}

class _SongOptionsSheetState extends State<SongOptionsSheet> {
  late Future<int> _cacheSize = _measureCache();
  Future<int> _measureCache() => context.read<SongCache>().size(widget.song);
  void _refresh() => setState(() {
    _cacheSize = _measureCache();
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.read<SongRepository>(),
      builder: (context, child) {
        // Any update to the history could be an update to *this* song.
        // Thus, we get the song from history each time we build instead of using
        // the song passed in the constructor.
        // For example, if the song is renamed while the sheet is open, it will
        // automatically be rebuilt with the correct information.
        final Song? song = context
            .read<SongRepository>()
            .getWhere(
              (song, _) => song.id == widget.song.id,
            )
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
                contentPadding: EdgeInsets.only(left: 4, right: 24),
                leading: SongTile.buildLeading(context, song),
                horizontalTitleGap: 4,
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
                                unawaited(
                                  context.read<SongRepository>().add(
                                    song.copyWith(
                                      title: controller.text,
                                    ),
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
              FutureBuilder<int>(
                future: _cacheSize,
                builder: (context, snapshot) {
                  final cacheSize = snapshot.data ?? 0;

                  return ListTile(
                    enabled: cacheSize > 0,
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
                                onPressed: () async {
                                  switch (await context
                                      .read<ClearSongCache>()
                                      .call(song)) {
                                    case Ok():
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }

                                    case Failure(:final error):
                                      debugPrint(
                                        "[Songs] Couldn't clear cache: $error",
                                      );
                                    // TODO: Show error snackbar
                                  }

                                  _refresh();
                                },
                                child: const Text("Clear"),
                              ),
                            ],
                          );
                        },
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
                              context.read<SongRepository>().remove(song);
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
