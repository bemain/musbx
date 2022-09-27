import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';
import 'package:youtube_api/youtube_api.dart';

const String apiKey = "AIzaSyAoBBNr77PXXKZ7zOLbNVXOPzTjgu58sN4";

class YoutubeButton extends StatelessWidget {
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
      child: const Icon(Icons.search_rounded),
    );
  }

  Duration parseDuration(String s) {
    List<String> parts = s.split(":");
    return Duration(
      minutes: int.parse(parts[0]),
      seconds: int.parse(parts[1]),
    );
  }
}

class YoutubeSearchDelegate extends SearchDelegate<YouTubeVideo?> {
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
  Widget buildResults(BuildContext context) {
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
                  width: 120,
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
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Text(
                        video.channelTitle,
                        softWrap: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      video.url,
                      softWrap: true,
                      style: Theme.of(context).textTheme.caption,
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

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
