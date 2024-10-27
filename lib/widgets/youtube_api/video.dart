import 'package:musbx/widgets/youtube_api/thumbnails.dart';

typedef YoutubeVideoId = String;
typedef YoutubeChannelId = String;

class YoutubeVideo {
  /// The ID that YouTube uses to uniquely identify the video.
  final YoutubeVideoId id;

  /// The video's url
  final String url;

  /// The video's title
  final String title;

  /// The video's description.
  final String description;

  /// The date and time that the video was published.
  final DateTime publishedAt;

  /// The ID that YouTube uses to uniquely identify the channel that the video was uploaded to.
  final YoutubeChannelId channelId;

  /// The url to the channel that the video was uploaded to.
  final String channelUrl;

  /// Channel title for the channel that the video belongs to.
  final String channelTitle;

  /// Thumbnail images associated with the video.
  final YoutubeVideoThumbnails thumbnails;

  YoutubeVideo.fromJson(dynamic data, {String? id})
      : thumbnails =
            YoutubeVideoThumbnails.fromMap(data['snippet']['thumbnails']),
        id = id ?? data['id'],
        url = "https://www.youtube.com/watch?v=${id ?? data['id']}",
        publishedAt = DateTime.parse(data['snippet']['publishedAt']),
        channelId = data['snippet']['channelId'],
        channelUrl =
            "https://www.youtube.com/channel/${data['snippet']['channelId']}",
        title = data['snippet']['title'],
        description = data['snippet']['description'],
        channelTitle = data['snippet']['channelTitle'];
}
