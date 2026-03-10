import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/library_page/song_tile.dart';
import 'package:musbx/songs/library_page/soundcloud_search.dart';
import 'package:musbx/songs/player/library.dart';
import 'package:musbx/songs/player/song.dart';

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
        final Iterable<Song> songHistory = SongLibrary.history
            .sorted(ascending: false)
            .where(
              (song) =>
                  song.title.toLowerCase().contains(query) ||
                  (song.artist?.toLowerCase().contains(query) ?? false),
            );

        return [
          const SizedBox(height: 8),
          for (final Song song in songHistory)
            SongTile(
              song: song,
              showOptions: false,
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
                          final Song song = await SongLibrary.addTrack(track);
                          if (context.mounted) {
                            context.go(Routes.song(song.id));
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
}
