import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/track_search_repository.dart';
import 'package:musbx/domain/models/online_track.dart';
import 'package:musbx/songs/library_page/search_bar.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/result_builder.dart';
import 'package:musbx/widgets/widgets.dart';
import 'package:provider/provider.dart';

/// Searches for tracks online, suggesting previous queries as the user types.
///
/// Closes with the track the user picked, or `null` if they went back.
class OnlineTrackSearchDelegate extends SearchDelegate<OnlineTrack?> {
  OnlineTrackSearchDelegate()
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
    final TrackSearchRepository search = context.read();

    if (search.history.entries.isEmpty && query.isEmpty) {
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

    final searchHistory = search.history.sorted().where(
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
    final TrackSearchRepository search = context.read();

    return ResultBuilder<List<OnlineTrack>>(
      future: search.searchTracks(query),
      failure: (context, error) => switch (error) {
        UnavailableException() => InfoPage(
          icon: Icon(Symbols.search_off),
          text: "Search is currently unavailable. Try again later.",
        ),
        _ => ErrorPage(
          text: "Search failed. $error",
        ),
      },
      loading: (context) => ListView(
        children: List.filled(10, OnlineTrackTile(track: null)),
      ),
      ok: (context, tracks) {
        if (tracks.isEmpty) {
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
          children: [
            for (final track in tracks)
              OnlineTrackTile(
                track: track,
                onTap: () async {
                  await search.history.add(query.trim());
                  if (context.mounted) close(context, track);
                },
              ),
          ],
        );
      },
    );
  }
}

/// One track in a list of search results. Shimmers as a placeholder when
/// [track] is `null`.
class OnlineTrackTile extends StatelessWidget {
  const OnlineTrackTile({
    super.key,
    required this.track,
    this.onTap,
  });

  /// The track to show, or `null` to shimmer as a placeholder.
  final OnlineTrack? track;

  /// Called when the item is tapped.
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
            : track!.artUri != null
            ? Image.network(
                track!.artUri!.toString(),
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
              track!.title,
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
                  if (track!.artist != null)
                    TextSpan(
                      text: track!.artist!,
                    ),
                  if (duration != null)
                    TextSpan(
                      text: " • $duration  ",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  if (track!.isPreview)
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
  String? formatDuration(OnlineTrack? track) {
    if (track?.duration == null) return null;
    final minutes = track!.duration!.inMinutes;
    final seconds = track.duration!.inSeconds.remainder(60);
    return "$minutes:${seconds.toString().padLeft(2, "0")}";
  }
}
