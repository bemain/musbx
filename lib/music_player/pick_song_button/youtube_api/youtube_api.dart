import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:musbx/music_player/pick_song_button/youtube_api/video.dart';

class YoutubeApi {
  /// Helper class for interacting with the Youtube Data API (https://developers.google.com/youtube/v3).
  YoutubeApi({required this.key});

  /// Headers used when performing a http request.
  static Map<String, String> httpHeaders = {"Accept": "application/json"};

  /// The api key used to access Youtube.
  String key;

  /// Get the video with [id] from Youtube, or null if no video with that [id].
  Future<YoutubeVideo?> getVideoById(YoutubeVideoId id) async {
    // Generate search query
    final Map<String, dynamic> options = {
      "id": [id],
      "part": "snippet",
      "key": key,
      "type": "video",
    };
    Uri url = Uri.https('www.googleapis.com', "youtube/v3/videos", options);

    // Do http get request
    final res = await http.get(url, headers: httpHeaders);
    var jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      debugPrint("[YOUTUBE] Error: ${jsonData['error']['message']}");
      return null;
    }

    if (jsonData["items"] == null || jsonData["items"].length < 1) return null;

    return YoutubeVideo.fromJson(jsonData["items"][0]);
  }

  /// Search Youtube for a given [query].
  Future<List<YoutubeVideo>> search(
    String query, {
    String type = 'video,channel,playlist',
    String order = 'relevance',
    String videoDuration = 'any',
    int maxResults = 10,
  }) async {
    // Generate search query
    final Map<String, dynamic> options = {
      "q": query,
      "part": "snippet",
      "maxResults": "$maxResults",
      "key": key,
      "type": type,
      "order": order,
      "videoDuration": videoDuration,
    };
    Uri url = Uri.https('www.googleapis.com', "youtube/v3/search", options);

    // Do http get request
    final res = await http.get(url, headers: httpHeaders);
    var jsonData = json.decode(res.body);
    if (jsonData['error'] != null) {
      debugPrint("[YOUTUBE] Error: ${jsonData['error']['message']}");
      return [];
    }

    // Map result to [YoutubeVideo]s
    if (jsonData['pageInfo']['totalResults'] == null) return [];
    List<YoutubeVideo> videos = [];
    for (var videoData in jsonData["items"]) {
      String kind = videoData['id']['kind'].substring(8);
      if (kind == "video") {
        videos.add(YoutubeVideo.fromJson(videoData,
            id: videoData['id'][videoData['id'].keys.elementAt(1)]));
      }
    }

    return videos;
  }
}
