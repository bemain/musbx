import 'dart:convert';

class YoutubeVideoThumbnails {
  final YoutubeVideoThumbnail small;
  final YoutubeVideoThumbnail medium;
  final YoutubeVideoThumbnail high;
  YoutubeVideoThumbnails({
    required this.small,
    required this.medium,
    required this.high,
  });

  YoutubeVideoThumbnails copyWith({
    YoutubeVideoThumbnail? small,
    YoutubeVideoThumbnail? medium,
    YoutubeVideoThumbnail? high,
  }) {
    return YoutubeVideoThumbnails(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      high: high ?? this.high,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'default': small.toMap(),
      'medium': medium.toMap(),
      'high': high.toMap(),
    };
  }

  factory YoutubeVideoThumbnails.fromMap(Map<String, dynamic> map) {
    return YoutubeVideoThumbnails(
      small: YoutubeVideoThumbnail.fromMap(map['default']),
      medium: YoutubeVideoThumbnail.fromMap(map['medium']),
      high: YoutubeVideoThumbnail.fromMap(map['high']),
    );
  }

  String toJson() => json.encode(toMap());

  factory YoutubeVideoThumbnails.fromJson(String source) =>
      YoutubeVideoThumbnails.fromMap(json.decode(source));

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
  const YoutubeVideoThumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;

  final int width;
  final int height;

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'width': width,
      'height': height,
    };
  }

  factory YoutubeVideoThumbnail.fromMap(Map<String, dynamic> map) {
    return YoutubeVideoThumbnail(
      url: map['url'],
      width: map['width'],
      height: map['height'],
    );
  }

  String toJson() => json.encode(toMap());

  factory YoutubeVideoThumbnail.fromJson(String source) =>
      YoutubeVideoThumbnail.fromMap(json.decode(source));
}
