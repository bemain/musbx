import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/models/soundcloud_track.dart';
import 'package:musbx/data/services/soundcloud_api_client.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/library_page/search_bar.dart';
import 'package:musbx/songs/player/library.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/utils/history_handler.dart';
import 'package:musbx/widgets/widgets.dart';

/// Provides functionality for searching and downloading SoundCloud tracks.
class SoundCloudSearch {
  /// Opens a SoundCloud search interface and allows the user to pick a song.
  ///
  /// This method displays a search dialog where users can search for tracks
  /// on SoundCloud. When a track is selected, it's automatically added to
  /// the user's library and the song page is opened.
  ///
  /// Optionally you can specify an initial search [query].
  static Future<void> pickSong(BuildContext context, {String? query}) async {
    SoundCloudTrack? track = await showSearch<SoundCloudTrack?>(
      context: context,
      delegate: SoundCloudSearchDelegate(),
      useRootNavigator: true,
      query: query ?? "",
    );

    if (track == null) return;

    final Song song = await SongLibrary.addTrack(track);

    if (context.mounted) context.go(Routes.song(song.id));
  }

  /// The history of previous search SoundCloud queries.
  static final HistoryHandler<String> history = HistoryHandler<String>(
    fromJson: (json) => json as String,
    toJson: (value) => value,
    historyFileName: "soundcloud_search_history",
  );

  static Future<List<SoundCloudTrack>> searchTracks(String query) =>
      SoundCloudApiClient.instance.searchTracks(query);
}

/// A search delegate that provides the SoundCloud search interface.
class SoundCloudSearchDelegate extends SearchDelegate<SoundCloudTrack?> {
  SoundCloudSearchDelegate()
    : super(
        searchFieldLabel: "Search online",
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
      );

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: const BackButtonIcon(),
    );
  }

  @override
  PreferredSizeWidget? buildBottom(BuildContext context) {
    return const PreferredSize(
      preferredSize: Size(double.infinity, 1.0),
      child: Divider(height: 1.0),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: query.isEmpty ? null : () => query = "",
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        icon: const Icon(Symbols.clear),
      ),
    ];
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (SoundCloudSearch.history.entries.isEmpty && query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LibrarySearchBar.placeholderIcon(context),
              const SizedBox(height: 16),
              Text(
                "Enter a search phrase to find songs online.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final searchHistory = SoundCloudSearch.history.sorted().where(
      (e) => e.toLowerCase().contains(query.toLowerCase()),
    );

    if (searchHistory.isEmpty) {
      return buildResults(context);
    }

    return ListView(
      children: [
        for (final historyQuery in searchHistory)
          ListTile(
            leading: Icon(
              Symbols.history,
              color: Theme.of(context).colorScheme.outline,
            ),
            title: Text(historyQuery),
            trailing: IconButton(
              onPressed: () => query = historyQuery,
              color: Theme.of(context).colorScheme.outline,
              icon: const RotatedBox(
                quarterTurns: -1,
                child: Icon(Symbols.arrow_outward),
              ),
            ),
            onTap: () {
              query = historyQuery;
              showResults(context);
            },
          ),
      ],
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (!SoundCloudApiClient.instance.isEnabled) {
      return InfoPage(
        icon: Icon(Symbols.search_off),
        text: "Search is currently unavailable. Try again later.",
      );
    }

    return FutureBuilder<List<SoundCloudTrack>>(
      future: SoundCloudSearch.searchTracks(query),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorPage(
            text: "Search failed. ${snapshot.error}",
          );
        }
        if (!snapshot.hasData) {
          return ListView(
            children: List.filled(10, SoundCloudTrackListItem(track: null)),
          );
        }

        List<SoundCloudTrack> results = snapshot.data!;

        if (results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.search_off, size: 64),
                SizedBox(height: 16),
                Text("No tracks found"),
                SizedBox(height: 8),
                Text("Try a different search term"),
              ],
            ),
          );
        }

        return ListView(
          children: results.map((track) {
            return SoundCloudTrackListItem(
              track: track,
              onTap: () async {
                await SoundCloudSearch.history.add(query.trim());
                if (context.mounted) close(context, track);
              },
            );
          }).toList(),
        );
      },
    );
  }
}

/// A list item widget that displays a SoundCloud track in search results.
///
/// This widget shows track information including artwork, title, artist,
/// duration, and download status. It handles loading states with placeholder
/// content and provides visual feedback for user interactions.
class SoundCloudTrackListItem extends StatelessWidget {
  /// HTML unescaper for cleaning up track titles and artist names.
  static final HtmlUnescape htmlUnescape = HtmlUnescape();

  /// Creates a new SoundCloud track list item.
  const SoundCloudTrackListItem({
    super.key,
    required this.track,
    this.onTap,
  });

  /// The SoundCloud track to display, or null for loading state.
  final SoundCloudTrack? track;

  /// Callback function called when the item is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final String? duration = formatDuration(track);

    return ListTile(
      onTap: onTap,
      minLeadingWidth: 64,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: track == null
            ? ShimmerLoading(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  width: 64,
                  height: 64,
                ),
              )
            : track!.artworkUrl != null
            ? Image.network(
                track!.artworkUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    buildDefaultLeading(context),
              )
            : buildDefaultLeading(context),
      ),
      title: track == null
          ? const TextPlaceholder()
          : Text(
              htmlUnescape.convert(track!.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      subtitle: track == null
          ? const Align(
              alignment: Alignment.centerLeft,
              child: TextPlaceholder(width: 160),
            )
          : RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                children: [
                  if (track!.username != null)
                    TextSpan(
                      text: htmlUnescape.convert(track!.username!),
                    ),
                  if (duration != null)
                    TextSpan(
                      text: " • $duration  ",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  if (track!.policy == "SNIP")
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Symbols.award_star,
                        size: 12,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  Widget buildDefaultLeading(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      width: 64,
      height: 64,
      child: Icon(
        Symbols.music_note,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Returns the duration formatted as "MM:SS".
  String? formatDuration(SoundCloudTrack? track) {
    if (track?.duration == null) return null;
    final minutes = track!.duration!.inMinutes;
    final seconds = track.duration!.inSeconds.remainder(60);
    return "$minutes:${seconds.toString().padLeft(2, "0")}";
  }
}
