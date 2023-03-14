class YoutubeVideoThumbnails {
  /// Thumbnail images associated with a [YoutubeVideo].
  YoutubeVideoThumbnails({
    required this.small,
    required this.medium,
    required this.high,
  });

  /// The default thumbnail image.
  final YoutubeVideoThumbnail small;

  /// A higher resolution version of the thumbnail image.
  final YoutubeVideoThumbnail medium;

  /// A high resolution version of the thumbnail image.
  final YoutubeVideoThumbnail high;

  YoutubeVideoThumbnails.fromMap(Map<String, dynamic> map)
      : small = YoutubeVideoThumbnail.fromMap(map['default']),
        medium = YoutubeVideoThumbnail.fromMap(map['medium']),
        high = YoutubeVideoThumbnail.fromMap(map['high']);

  @override
  String toString() =>
      'Thumbnails(default: $small, medium: $medium, high: $high)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is YoutubeVideoThumbnails &&
        other.small == small &&
        other.medium == medium &&
        other.high == high;
  }

  @override
  int get hashCode => small.hashCode ^ medium.hashCode ^ high.hashCode;
}

class YoutubeVideoThumbnail {
  /// A thumbnail image of a specific size, associated with a [YoutubeVideo].
  const YoutubeVideoThumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  /// The thumbnail's url.
  final String url;

  /// The width of the thumbnail.
  final int width;

  /// The height of the thumbnail.
  final int height;

  factory YoutubeVideoThumbnail.fromMap(Map<String, dynamic> map) {
    return YoutubeVideoThumbnail(
      url: map['url'],
      width: map['width'],
      height: map['height'],
    );
  }
}
