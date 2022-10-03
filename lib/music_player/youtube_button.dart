import 'package:flutter/material.dart';
import 'package:musbx/custom_icons.dart';
import 'package:musbx/music_player/api_key.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';
import 'package:youtube_api/youtube_api.dart';

class YoutubeButton extends StatelessWidget {
  /// Button for searching for a song from Youtube and loading it to [MusicPlayer].
  const YoutubeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        YouTubeVideo? video = await showSearch<YouTubeVideo?>(
          context: context,
          delegate: YoutubeSearchDelegate(),
        );

        if (video != null) {
          MusicPlayer.instance.playVideo(video);
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
class YoutubeSearchDelegate extends SearchDelegate<YouTubeVideo?> {
  /// Previous search queries.
  static Set<String> searchHistory = {};

  /// The API key used to access Youtube.
  final YoutubeAPI youtubeApi = YoutubeAPI(apiKey);

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
      future: youtubeApi.search(query, type: "video"),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingScreen(text: "Searching...");
        if (snapshot.hasError) return const ErrorScreen(text: "Search failed");

        List<YouTubeVideo> results = snapshot.data!;
        return ListView(
          children: results.map((YouTubeVideo video) {
            return listItem(context, video);
          }).toList(),
        );
      },
    );
  }

  /// Result item, showing a [YouTubeVideo]'s title, channel and thumbnail.
  Widget listItem(BuildContext context, YouTubeVideo video) {
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
                  video.thumbnail.small.url ?? '',
                  width: 100,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      video.title,
                      softWrap: true,
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Text(
                        video.channelTitle,
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
