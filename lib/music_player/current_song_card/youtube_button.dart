import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:musbx/custom_icons.dart';
import 'package:musbx/music_player/api_key.dart';
import 'package:musbx/music_player/current_song_card/youtube_api/video.dart';
import 'package:musbx/music_player/current_song_card/youtube_api/youtube_api.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';
import 'package:youtube_api/youtube_api.dart';

class YoutubeButton extends StatelessWidget {
  /// Button for searching for a song from Youtube and loading it to [MusicPlayer].
  const YoutubeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return OutlinedButton(
      onPressed: musicPlayer.isLoading
          ? null
          : () async {
              MusicPlayerState prevState = musicPlayer.state;
              musicPlayer.stateNotifier.value = MusicPlayerState.pickingAudio;

              YoutubeVideo? video = await showSearch<YoutubeVideo?>(
                context: context,
                delegate: YoutubeSearchDelegate(),
              );

              if (video != null) {
                musicPlayer.playVideo(video);
              } else {
                // Restore state
                musicPlayer.stateNotifier.value = prevState;
              }
            },
      child: const Icon(CustomIcons.youtube),
    );
  }

  /// Parse [String] to [Duration].
  Duration parseDuration(String s) {
    List<String> parts = s.split(":");
    return Duration(
      minutes: int.parse(parts[0]),
      seconds: int.parse(parts[1]),
    );
  }
}

/// [SearchDelegate] for searching for a song on Youtube.
class YoutubeSearchDelegate extends SearchDelegate<YoutubeVideo?> {
  /// Previous search queries.
  static Set<String> searchHistory = {};

  /// The API key used to access Youtube.
  final YoutubeApi youtubeApi = YoutubeApi(key: apiKey);

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = "";
        },
        icon: const Icon(Icons.clear_rounded),
      )
    ];
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(
      children: searchHistory
          .map((query) => ListTile(
                title: Text(query),
                onTap: () {
                  this.query = query;
                  showResults(context);
                },
              ))
          .toList(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query != "") searchHistory.add(query.trim());

    return FutureBuilder(
      future: _getVideosFromQuery(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingScreen(text: "Searching...");
        if (snapshot.hasError) return const ErrorScreen(text: "Search failed");

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
        await youtubeApi.getVideoById(query.replaceAll(' ', ''));
    if (videoById != null) return [videoById];

    return await youtubeApi.search(query, type: "video", maxResults: 50);
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
                      style: Theme.of(context).textTheme.subtitle1,
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
