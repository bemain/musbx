import 'dart:convert';

import 'package:http/http.dart' as http;

typedef YoutubeVideoId = String;
typedef YoutubeChannelId = String;

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

class YoutubeApi {
  static String baseURL = 'www.googleapis.com';
  static Map<String, String> headers = {"Accept": "application/json"};

  YoutubeApi({required this.key});

  String key;

  Future<List<YoutubeVideo>> search(
    String query, {
    String type = 'video,channel,playlist',
    String order = 'relevance',
    String videoDuration = 'any',
    int maxResults = 10,
  }) async {
    final url = _generateSearchUri(
      query,
      key: key,
      maxResults: maxResults,
      type: type,
      videoDuration: videoDuration,
      order: order,
    );
    var res = await http.get(url, headers: headers);
    var jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      throw jsonData['error']['message'];
    }
    if (jsonData['pageInfo']['totalResults'] == null) return <YoutubeVideo>[];
    List<YoutubeVideo> videos = [];
    for (var videoData in jsonData["items"]) {
      String kind = videoData['id']['kind'].substring(8);
      if (kind == "video") {
        videos.add(YoutubeVideo.fromJson(videoData));
      }
    }

    return videos;
  }

  Uri _generateSearchUri(
    String query, {
    required String key,
    int maxResults = 10,
    required String type,
    String? regionCode,
    required String videoDuration,
    required String order,
  }) {
    final options = {
      "q": query,
      "part": "snippet",
      "maxResults": "$maxResults",
      "key": key,
      "type": type,
      "order": order,
      "videoDuration": videoDuration,
    };
    if (regionCode != null) options['regionCode'] = regionCode;
    Uri url = Uri.https(baseURL, "youtube/v3/search", options);
    return url;
  }
}
