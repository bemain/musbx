import 'package:flutter/material.dart';
import 'package:flutter_m3shapes/flutter_m3shapes.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/repositories/song/track_search_repository.dart';
import 'package:musbx/domain/models/online_track.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/routing/routes.dart';
import 'package:musbx/songs/library_page/online_track_search.dart';
import 'package:musbx/songs/library_page/song_tile.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/result_builder.dart';
import 'package:provider/provider.dart';

/// Searches the library as the user types, listing matching tracks found
/// online below the songs already in it.
class LibrarySearchBar extends StatefulWidget {
  const LibrarySearchBar({super.key});

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();

  /// The artwork stand-in for a search result that has none.
  static Widget placeholderIcon(BuildContext context, {Color? color}) {
    return M3Container.c4SidedCookie(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Icon(
          Symbols.search,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
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
            hintText: "Search for songs",
          ),
        );
      },
      viewHintText: "Search for songs",
      suggestionsBuilder: (context, controller) {
        final String query = controller.text.toLowerCase();
        if (query.isEmpty) {
          return [
            const SizedBox(height: 32),
            LibrarySearchBar.placeholderIcon(
              context,
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            const SizedBox(height: 16),
            Text(
              "Enter a search phrase to find songs.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ];
        }

        // History entries that match the search query
        final Iterable<Song> songHistory = context
            .read<SongRepository>()
            .getAll(order: GetOrder.descending)
            .where(
              (song) =>
                  song.title.toLowerCase().contains(query) ||
                  (song.artist?.toLowerCase().contains(query) ?? false),
            );

        final TrackSearchRepository search = context.read();

        return [
          const SizedBox(height: 8),
          for (final Song song in songHistory)
            SongTile(
              song: song,
              showOptions: false,
              leadingColor: Theme.of(context).colorScheme.surfaceContainer,
              onSelected: () {
                controller.closeView(null);
              },
            ),
          if (songHistory.isNotEmpty) const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ResultBuilder(
              future: search
                  .searchTracks(query)
                  .timeout(
                    Duration(seconds: 2),
                    onTimeout: () => Result.cancelled(),
                  ),
              failure: (context, error) => const SizedBox(),
              loading: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Results online",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (var i = 0; i < 10; i++) OnlineTrackTile(track: null),
                ],
              ),
              ok: (context, tracks) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Results online",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final OnlineTrack track in tracks)
                      OnlineTrackTile(
                        track: track,
                        onTap: () async {
                          this.controller.closeView(null);
                          final result = await context
                              .read<SongRepository>()
                              .addTrack(
                                track,
                              );
                          switch (result) {
                            case Ok(value: final song):
                              if (context.mounted) {
                                context.go(Routes.song(song.id));
                              }
                            case Failure(:final error):
                              debugPrint(
                                "[Library] Failed to add online track; $error",
                              );
                            // TODO: Show error snackbar
                          }
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ];
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
