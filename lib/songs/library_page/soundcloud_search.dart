import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/keys.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/songs/player/source.dart';
import 'package:musbx/utils/loading.dart';
import 'package:musbx/widgets/widgets.dart';
import 'package:musbx/utils/history_handler.dart';
import 'package:http/http.dart' as http;

/// Represents a transcoding format for a SoundCloud track.
class SoundCloudTrackTranscoding {
  /// The URL to access this transcoding format.
  final String url;

  /// The MIME type of the audio format (e.g., "audio/mpeg").
  final String mimeType;

  /// The protocol used for streaming (e.g., "progressive" for direct download).
  final String protocol;

  /// The quality level of this transcoding (e.g., "sq", "hq").
  final String quality;

  /// Creates a new [SoundCloudTrackTranscoding] instance.
  SoundCloudTrackTranscoding({
    required this.url,
    required this.mimeType,
    required this.protocol,
    required this.quality,
  });

  /// Creates a [SoundCloudTrackTranscoding] from a JSON object.
  factory SoundCloudTrackTranscoding.fromJson(Map<String, dynamic> json) {
    return SoundCloudTrackTranscoding(
      url: json["url"],
      mimeType: json["format"]["mime_type"],
      protocol: json["format"]["protocol"],
      quality: json["quality"],
    );
  }
}

/// Represents a SoundCloud track with all its metadata and streaming information.
class SoundCloudTrack {
  /// The unique identifier for this track on SoundCloud.
  final int id;

  /// The title of the track.
  final String title;

  /// The username of the track's creator/artist.
  final String username;

  /// URL to the track's artwork image, if available.
  final String? artworkUrl;

  /// The permalink URL to view this track on SoundCloud.
  final String permalinkUrl;

  /// The duration of the track.
  final Duration duration;

  /// Whether the track can be streamed.
  final bool streamable;

  /// Whether the track is available for download.
  final bool downloadable;

  /// List of available transcoding formats for this track.
  final List<SoundCloudTrackTranscoding> transcodings;

  SoundCloudTrack({
    required this.id,
    required this.title,
    required this.username,
    this.artworkUrl,
    required this.permalinkUrl,
    required this.duration,
    this.streamable = false,
    this.downloadable = false,
    required this.transcodings,
  });

  /// Creates a [SoundCloudTrack] from a JSON object.
  factory SoundCloudTrack.fromJson(Map<String, dynamic> json) {
    return SoundCloudTrack(
      id: json["id"] ?? 0,
      title: json["title"] ?? "Unknown Title",
      username: json["user"]?["username"] ?? "Unknown Artist",
      artworkUrl: json["artwork_url"],
      permalinkUrl: json["permalink_url"] ?? "",
      duration: Duration(milliseconds: json["duration"] ?? 0),
      streamable: json["streamable"] ?? false,
      downloadable: json["downloadable"] ?? false,
      transcodings: (json["media"]["transcodings"] as List<dynamic>?)
              ?.map((e) => SoundCloudTrackTranscoding.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Returns the duration formatted as "MM:SS".
  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "$minutes:${seconds.toString().padLeft(2, "0")}";
  }

  /// Gets the actual download URL for this track.
  ///
  /// This method performs an additional API call to resolve the streaming URL
  /// from SoundCloud's transcoding system. It prefers MP3 format with
  /// progressive protocol for direct downloading.
  Future<Uri> getDownloadUrl() async {
    final Uri uri = Uri.parse(transcodings
            .firstWhere(
              (t) => t.mimeType == "audio/mpeg" && t.protocol == "progressive",
              orElse: () => transcodings.first,
            )
            .url)
        .replace(queryParameters: {
      "client_id": soundCloudClientId,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception(
          "Failed to get SoundCloud download URL: ${res.statusCode}");
    }

    return Uri.parse(json.decode(res.body)["url"]);
  }
}

/// Provides functionality for searching and selecting SoundCloud tracks.
///
/// This class handles all SoundCloud API interactions, including searching
/// for tracks and managing search history. It serves as the main entry point
/// for SoundCloud integration in the app.
///
/// **Important**: This implementation uses SoundCloud's streaming API, which
/// may have terms of service restrictions. Ensure compliance with SoundCloud's
/// developer terms before using in production.
class SoundCloudSearch {
  /// Base URL for SoundCloud's API v2.
  static const String _baseUrl = "https://api-v2.soundcloud.com";

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

    await loadTrack(track);

    if (context.mounted) context.go(Navigation.songRoute(track.id.toString()));
  }

  /// Loads a track from SoundCloud into the user's library.
  static Future<void> loadTrack(SoundCloudTrack track) async {
    await Songs.history.add(Song<SinglePlayable>(
      id: track.id.toString(),
      title: HtmlUnescape().convert(track.title),
      artist: HtmlUnescape().convert(track.username),
      artUri: track.artworkUrl != null ? Uri.tryParse(track.artworkUrl!) : null,
      source:
          SoundCloudSource(track.id.toString(), await track.getDownloadUrl()),
    ));
  }

  /// Searches for tracks on SoundCloud using the provided [query].
  static Future<List<SoundCloudTrack>> searchTracks(String query) async {
    final uri = Uri.parse("$_baseUrl/search/tracks").replace(queryParameters: {
      "q": query,
      "client_id": soundCloudClientId,
      "limit": "50",
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception("Failed to search SoundCloud: ${response.statusCode}");
    }

    final List<dynamic> data = json.decode(response.body)["collection"];
    return data.map((track) => SoundCloudTrack.fromJson(track)).toList();
  }

  /// The history of previous search SoundCloud queries.
  static final HistoryHandler<String> history = HistoryHandler<String>(
    fromJson: (json) => json as String,
    toJson: (value) => value,
    historyFileName: "soundcloud_search_history",
  );
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
      )
    ];
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (SoundCloudSearch.history.entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.search,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
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

    final searchHistory = SoundCloudSearch.history
        .sorted()
        .where((e) => e.toLowerCase().contains(query.toLowerCase()));

    return ListView(children: [
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
    ]);
  }

  @override
  Widget buildResults(BuildContext context) {
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
                Text("No downloadable tracks found"),
                SizedBox(height: 8),
                Text("Try a different search term"),
              ],
            ),
          );
        }

        return ListView(
          children: results.map((SoundCloudTrack track) {
            return SoundCloudTrackListItem(
              track: track,
              onTap: () {
                SoundCloudSearch.history.add(query.trim());
                close(context, track);
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
    return ListTile(
        onTap: onTap,
        minLeadingWidth: 64,
        leading: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: track == null
                ? Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    width: 64,
                    height: 64,
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
                    : buildDefaultLeading(context)),
        title: track == null
            ? const TextPlaceholder()
            : Text(
                htmlUnescape.convert(track!.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        subtitle: track == null
            ? const TextPlaceholder(width: 160)
            : RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  children: [
                    TextSpan(
                      text: htmlUnescape.convert(track!.username),
                    ),
                    TextSpan(
                      text: " • ${track!.durationFormatted}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: track == null ? IconPlaceholder() : Icon(Symbols.download));
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
}
