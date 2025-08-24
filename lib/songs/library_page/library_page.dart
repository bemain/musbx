import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/library_page/soundcloud_search.dart';
import 'package:musbx/songs/library_page/upload_file_button.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/widgets/speed_dial/speed_dial.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            scrolledUnderElevation: 0,
            toolbarHeight: 68,
            expandedHeight: 128,
            title: LibrarySearchBar(),
            actions: const [
              GetPremiumButton(),
              InfoButton(),
            ],
          ),
          ListenableBuilder(
            listenable: Songs.history,
            builder: (context, child) {
              return SliverList.list(
                children: [
                  const SizedBox(height: 8),
                  for (final Song song in Songs.history.sorted(
                    ascending: false,
                  ))
                    _buildSongTile(context, song),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildLoadSongFAB(context),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    Song song, {
    void Function()? onSelected,
  }) {
    final bool isLocked =
        Songs.isAccessRestricted &&
        !Songs.songsPlayedThisWeek.contains(song) &&
        song != demoSong;
    final TextStyle? textStyle = !isLocked
        ? null
        : TextStyle(color: Theme.of(context).disabledColor);

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 20, right: 8),
      leading: isLocked
          ? Icon(
              Symbols.lock,
              color: Theme.of(context).disabledColor,
            )
          : _buildSongIcon(song),
      title: Text(
        song.title,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist ?? "Unknown artist",
        style: textStyle,
      ),
      trailing: IconButton(
        onPressed: () {
          _showOptionsSheet(context, song);
        },
        icon: const Icon(Symbols.more_vert),
      ),
      onTap: () async {
        if (isLocked) {
          await showExceptionDialog(
            const MusicPlayerAccessRestrictedDialog(),
          );
          return;
        }

        onSelected?.call();
        context.go(Navigation.songRoute(song.id));
      },
      onLongPress: () {
        _showOptionsSheet(context, song);
      },
    );
  }

  void _showOptionsSheet(BuildContext context, Song song) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _buildOptionsSheet(context, song),
    );
  }

  Widget _buildOptionsSheet(BuildContext context, Song song) {
    return ListTileTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      minLeadingWidth: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          ListTile(
            leading: _buildSongIcon(song),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            subtitle: Text(
              song.artist ?? "Unknown artist",
            ),
            trailing: song.source is DemixedSource
                ? null
                : const Tooltip(
                    message:
                        "This song has not been demixed into instruments.",
                    child: Icon(Symbols.piano_off),
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
            enabled: song.cacheDirectory.existsSync(),
            leading: const Icon(Symbols.delete_sweep),
            title: const Text("Clear cached files"),
            onTap: () {
              showDialog<void>(
                context: context,
                useRootNavigator: true,
                builder: (context) {
                  return AlertDialog(
                    icon: const Icon(Symbols.delete_sweep),
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
                          song.cacheDirectory.delete(recursive: true);
                          if (song.source is DemixedSource) {
                            // Override the history entry for the song with a non-demixed variant
                            Songs.history.add(
                              song.withSource<SinglePlayable>(
                                (song.source as DemixedSource).rootParent,
                              ),
                            );
                          }
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
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
            leading: const Icon(Symbols.delete_forever),
            title: const Text("Remove from library"),
            onTap: () {
              showDialog<void>(
                context: context,
                useRootNavigator: true,
                builder: (context) {
                  return AlertDialog(
                    icon: const Icon(Symbols.delete_forever),
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
  }

  Widget _buildLoadSongFAB(BuildContext context, {Object? heroTag}) {
    return SpeedDial.extended(
      heroTag: heroTag,
      shouldExpand: () {
        if (Songs.isAccessRestricted) {
          showExceptionDialog(const MusicPlayerAccessRestrictedDialog());
        }

        return !Songs.isAccessRestricted;
      },
      onExpandedPressed: () => SoundCloudSearch.pickSong(context),
      expandedChild: const Icon(Symbols.search),
      expandedLabel: const Text("Search"),
      children: [
        UploadSongButton(),
      ],
      label: const Text("Add to library"),
      child: const Icon(Symbols.add),
    );
  }

  Widget _buildSongIcon(Song song) {
    if (song == demoSong) {
      return const Icon(Symbols.science);
    }
    return Icon(_getSourceIcon(song.source));
  }
}

IconData _getSourceIcon(SongSource source) {
  return switch (source) {
    FileSource() => Symbols.file_present,
    YtdlpSource() => Symbols.music_note,
    DemixedSource() => _getSourceIcon(source.parent),
    _ => Symbols.music_note,
  };
}

class LibrarySearchBar extends StatefulWidget {
  const LibrarySearchBar({super.key});

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  late final SearchController controller = SearchController();

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: controller,
      builder: (context, controller) {
        return const AbsorbPointer(
          child: SearchBar(
            elevation: WidgetStatePropertyAll(0.0),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            leading: Icon(Symbols.search),
            hintText: "Search your library",
          ),
        );
      },
      viewHintText: "Search your library",
      suggestionsBuilder: (context, controller) {
        final String query = controller.text.toLowerCase();
        if (query.isEmpty) return const [];

        // History entries that match the search query
        final Iterable<Song> songHistory = Songs.history
            .sorted(ascending: false)
            .where(
              (song) =>
                  song.title.toLowerCase().contains(query) ||
                  (song.artist?.toLowerCase().contains(query) ?? false),
            );

        return [
          const SizedBox(height: 8),
          for (final Song song in songHistory)
            _buildSongTile(
              context,
              song,
              onSelected: () {
                controller.closeView(null);
              },
            ),
          if (songHistory.isNotEmpty) const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Results online",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          FutureBuilder(
            future: SoundCloudSearch.searchTracks(
              query,
            ).timeout(Duration(seconds: 2), onTimeout: () => []),
            builder: (context, snapshot) {
              if (snapshot.hasError) return SizedBox();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (snapshot.hasData)
                    for (final SoundCloudTrack track in snapshot.requireData)
                      SoundCloudTrackListItem(
                        track: track,
                        onTap: () async {
                          this.controller.closeView(null);
                          await SoundCloudSearch.loadTrack(track);
                          if (context.mounted) {
                            context.go(
                              Navigation.songRoute(track.id.toString()),
                            );
                          }
                        },
                      )
                  else
                    for (var i = 0; i < 10; i++)
                      SoundCloudTrackListItem(track: null),
                ],
              );
            },
          ),
        ];
      },
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    Song song, {
    void Function()? onSelected,
  }) {
    final bool isLocked =
        Songs.isAccessRestricted &&
        !Songs.songsPlayedThisWeek.contains(song) &&
        song != demoSong;
    final TextStyle? textStyle = !isLocked
        ? null
        : TextStyle(color: Theme.of(context).disabledColor);

    return ListTile(
      minLeadingWidth: 64,
      leading: SizedBox(
        width: 64,
        height: 64,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          child: isLocked
              ? Icon(
                  Symbols.lock,
                  color: Theme.of(context).disabledColor,
                )
              : _buildSongIcon(song),
        ),
      ),
      title: Text(
        song.title,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist ?? "Unknown artist",
        style: textStyle,
      ),
      onTap: () async {
        if (isLocked) {
          await showExceptionDialog(
            const MusicPlayerAccessRestrictedDialog(),
          );
          return;
        }

        onSelected?.call();
        context.go(Navigation.songRoute(song.id));
      },
    );
  }

  Widget _buildSongIcon(Song song) {
    if (song == demoSong) {
      return const Icon(Symbols.science);
    }
    return Icon(_getSourceIcon(song.source));
  }
}
