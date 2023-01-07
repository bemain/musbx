import 'package:musbx/music_player/current_song_card/youtube_api/thumbnails.dart';

typedef YoutubeVideoId = String;
typedef YoutubeChannelId = String;

class YoutubeVideo {
  final YoutubeVideoId id;
  final String url;

  final YoutubeChannelId channelId;
  final String channelUrl;
  final String channelTitle;

  final String title;
  final String description;
  final DateTime publishedAt;

  final YoutubeVideoThumbnails thumbnails;

  YoutubeVideo.fromJson(dynamic data)
      : thumbnails =
            YoutubeVideoThumbnails.fromMap(data['snippet']['thumbnails']),
        id = data['id'][data['id'].keys.elementAt(1)],
        url =
            "https://www.youtube.com/watch?v=${data['id'][data['id'].keys.elementAt(1)]}",
        publishedAt = DateTime.parse(data['snippet']['publishedAt']),
        channelId = data['snippet']['channelId'],
        channelUrl =
            "https://www.youtube.com/channel/${data['snippet']['channelId']}",
        title = data['snippet']['title'],
        description = data['snippet']['description'],
        channelTitle = data['snippet']['channelTitle'];
}
