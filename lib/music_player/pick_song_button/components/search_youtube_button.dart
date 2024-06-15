import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:musbx/music_player/pick_song_button/youtube_api/video.dart';
import 'package:musbx/music_player/pick_song_button/youtube_api/youtube_api.dart';
import 'package:musbx/music_player/exception_dialogs.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/history_handler.dart';
import 'package:musbx/widgets.dart';

/// Open a full-screen dialog that allows the user to search for and pick a song from Youtube.
Future<void> pickYoutubeSong(BuildContext context) async {
  MusicPlayer musicPlayer = MusicPlayer.instance;
  MusicPlayerState prevState = musicPlayer.state;
  musicPlayer.stateNotifier.value = MusicPlayerState.pickingAudio;

  YoutubeVideo? video = await showSearch<YoutubeVideo?>(
    context: context,
    delegate: YoutubeSearchDelegate(),
  );

  if (video == null) {
    // Restore state
    musicPlayer.stateNotifier.value = prevState;
    return;
  }

  try {
    await musicPlayer.loadVideo(video);
    return;
  } catch (error) {
    debugPrint("[YOUTUBE] $error");
    showExceptionDialog(
      const YoutubeUnavailableDialog(),
    );

    // Restore state
    musicPlayer.stateNotifier.value = prevState;
    return;
  }
}

/// The history of previous search queries.
final HistoryHandler<String> youtubeSearchHistory = HistoryHandler<String>(
  fromJson: (json) => json as String,
  toJson: (value) => value,
  historyFileName: "search_history",
  maxEntries: 10,
);

/// [SearchDelegate] for searching for a song on Youtube.
class YoutubeSearchDelegate extends SearchDelegate<YoutubeVideo?> {
  YoutubeSearchDelegate() : super(searchFieldLabel: "Search YouTube");

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
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
        onPressed: () {
          query = "";
        },
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        icon: const Icon(Icons.clear),
      )
    ];
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (youtubeSearchHistory.history.isEmpty) {
      // Help text
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Text(
          "Enter a search phrase or paste a URL to a video on YouTube.",
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListenableBuilder(
      listenable: youtubeSearchHistory,
      builder: (context, child) => ListView(
        children: youtubeSearchHistory.sorted().map((query) {
          return ListTile(
            leading: Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.outline,
            ),
            title: Text(query),
            trailing: IconButton(
              onPressed: () => this.query = query,
              color: Theme.of(context).colorScheme.outline,
              icon: const RotatedBox(
                quarterTurns: -1,
                child: Icon(Icons.arrow_outward),
              ),
            ),
            onTap: () {
              this.query = query;
              showResults(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query != "") youtubeSearchHistory.add(query.trim());

    return FutureBuilder(
      future: _getVideosFromQuery(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingPage(text: "Searching...");
        if (snapshot.hasError) return const ErrorPage(text: "Search failed");

        List<YoutubeVideo> results = snapshot.data!;
        return ListView(
          children: results.map((YoutubeVideo video) {
            return listItem(context, video);
          }).toList(),
        );
      },
    );
  }

  Future<List<YoutubeVideo>> _getVideosFromQuery(String query) async {
    // Try using the [query] as a video url
    if (query.startsWith("https://")) {
      List<String> urlSegments = query.substring(8).split("/");
      if (urlSegments[1].startsWith("watch")) {
        // Full video url, with channel id
        query = urlSegments[1].split("&")[0].substring(8);
      } else {
        // Short video url
        query = urlSegments[1];
      }
    }

    // Try using the [query] as a video id
    final YoutubeVideo? videoById =
        await YoutubeDataApi.getVideoById(query.replaceAll(' ', ''));
    if (videoById != null) return [videoById];

    return await YoutubeDataApi.search(query, type: "video", maxResults: 50);
  }

  /// Result item, showing a [YouTubeVideo]'s title, channel and thumbnail.
  Widget listItem(BuildContext context, YoutubeVideo video) {
    HtmlUnescape htmlUnescape = HtmlUnescape();

    return GestureDetector(
      onTap: () {
        close(context, video);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Image.network(
                  video.thumbnails.small.url,
                  width: 100,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      htmlUnescape.convert(video.title),
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Text(
                        htmlUnescape.convert(video.channelTitle),
                        softWrap: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
