import 'package:musbx/utils/utils.dart';

/// The id Youtube identifies a video by, as it appears in a `watch?v=` url.
typedef YoutubeVideoId = String;

/// The id Youtube identifies a channel by.
typedef YoutubeChannelId = String;

/// A video as the Youtube Data API describes it.
///
/// A wire type: the fields are Youtube's, and a repository maps them to the
/// app's own models before anything above it sees them.
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

  /// Read a video from one entry of a Youtube Data API response.
  ///
  /// [id] has to be supplied for search results, where `id` is an object naming
  /// what kind of thing was found rather than the plain string it is when a
  /// video is fetched directly.
  YoutubeVideo.fromJson(Json json, {String? id})
    : thumbnails = YoutubeVideoThumbnails.fromJson(
        json['snippet']['thumbnails'] as Json,
      ),
      id = id ?? json['id'] as String,
      url = "https://www.youtube.com/watch?v=${id ?? json['id']}",
      publishedAt = DateTime.parse(json['snippet']['publishedAt'] as String),
      channelId = json['snippet']['channelId'] as String,
      channelUrl =
          "https://www.youtube.com/channel/${json['snippet']['channelId']}",
      title = json['snippet']['title'] as String,
      description = json['snippet']['description'] as String,
      channelTitle = json['snippet']['channelTitle'] as String;
}

/// Thumbnail images associated with a [YoutubeVideo].
class YoutubeVideoThumbnails {
  /// The default thumbnail image.
  final YoutubeVideoThumbnail small;

  /// A higher resolution version of the thumbnail image.
  final YoutubeVideoThumbnail medium;

  /// A high resolution version of the thumbnail image.
  final YoutubeVideoThumbnail high;

  YoutubeVideoThumbnails.fromJson(Json json)
    : small = YoutubeVideoThumbnail.fromJson(json['default'] as Json),
      medium = YoutubeVideoThumbnail.fromJson(json['medium'] as Json),
      high = YoutubeVideoThumbnail.fromJson(json['high'] as Json);
}

/// A thumbnail image of a specific size, associated with a [YoutubeVideo].
class YoutubeVideoThumbnail {
  /// The thumbnail's url.
  final String url;

  /// The width of the thumbnail.
  final int width;

  /// The height of the thumbnail.
  final int height;

  YoutubeVideoThumbnail.fromJson(Json json)
    : url = json['url'] as String,
      width = json['width'] as int,
      height = json['height'] as int;
}
