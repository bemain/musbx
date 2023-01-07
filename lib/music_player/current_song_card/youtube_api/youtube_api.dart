import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:musbx/music_player/current_song_card/youtube_api/video.dart';

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
