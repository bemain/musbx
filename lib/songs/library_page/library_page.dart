import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/widgets/default_app_bar.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/songs/library_page/youtube_search.dart';
import 'package:musbx/songs/library_page/upload_file_button.dart';
import 'package:musbx/widgets/speed_dial/speed_dial.dart';
import 'package:musbx/songs/player/song.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({super.key});

  final SearchController searchController = SearchController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar.medium(
          pinned: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          toolbarHeight: 68,
          expandedHeight: 128,
          title: SearchAnchor(
            searchController: searchController,
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
            suggestionsBuilder: (context, SearchController controller) {
              final String searchPhrase = controller.text.toLowerCase();
              if (searchPhrase.isEmpty) {
                return const [];
              }

              final Iterable<Song> songHistory = Songs.history
                  .sorted(ascending: false)
                  .where((song) =>
                      song.title.toLowerCase().contains(searchPhrase) ||
                      (song.artist?.toLowerCase().contains(searchPhrase) ??
                          false));

              return [
                const SizedBox(height: 8),
                for (final Song song in songHistory)
                  _buildSongTile(
                    context,
                    song,
                    showOptions: false,
                    onSelected: () {
                      searchController.closeView(null);
                    },
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        searchController.closeView(null);
                        pickYoutubeSong(context, query: controller.text);
                      },
                      icon: const Icon(Symbols.search),
                      label: Text(
                        "Search for '${controller.text}' online",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ];
            },
          ),
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
                for (final Song song in Songs.history.sorted(ascending: false))
                  _buildSongTile(context, song),
                const SizedBox(height: 80),
              ],
            );
          },
        )
      ]),
      floatingActionButton: _buildLoadSongFAB(context),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    Song song, {
    bool showOptions = true,
    Function()? onSelected,
  }) {
    final bool isLocked = Songs.isAccessRestricted &&
        !Songs.songsPlayedThisWeek.contains(song) &&
        song != demoSong;
    final TextStyle? textStyle =
        !isLocked ? null : TextStyle(color: Theme.of(context).disabledColor);

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
      trailing: showOptions
          ? IconButton(
              onPressed: () {
                _showOptionsSheet(context, song);
              },
              icon: const Icon(Symbols.more_vert),
            )
          : null,
      onTap: () async {
        if (isLocked) {
          showExceptionDialog(const MusicPlayerAccessRestrictedDialog());
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
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
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
                        "This song has not been separated into instruments",
                    child: Icon(Symbols.piano_off),
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.delete),
            title: const Text("Remove from library"),
            onTap: () {
              showDialog(
                context: context,
                useRootNavigator: true,
                builder: (context) {
                  return AlertDialog(
                    icon: const Icon(Symbols.delete, weight: 600),
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
      onExpandedPressed: () => pickYoutubeSong(context),
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

  IconData _getSourceIcon(SongSource source) {
    if (source is FileSource) {
      return Symbols.file_present;
    }
    if (source is YoutubeSource) {
      return Symbols.youtube_searched_for;
    }
    if (source is DemixedSource) {
      return _getSourceIcon(source.parent);
    }
    return Symbols.music_note;
  }
}
