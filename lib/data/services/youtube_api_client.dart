import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musbx/data/models/youtube_video.dart';
import 'package:musbx/keys.dart';
import 'package:musbx/utils/utils.dart';

/// Searches Youtube for videos the user can add to their library.
///
/// Talks to the [Youtube Data API](https://developers.google.com/youtube/v3),
/// which unlike SoundCloud's is documented and versioned, but metered: every
/// request spends from a daily quota shared by everyone using the app. A search
/// costs a hundred times what looking a video up by its id does, which is why
/// [getVideoById] is worth trying first. Once the quota runs out every request
/// fails until it resets, so this failing for a whole day is a state the app has
/// to survive.
///
/// The videos handed back are [YoutubeVideo], Youtube's own vocabulary rather
/// than the app's. Mapping them to domain models is the repository's job;
/// nothing above it should see this type.
class YoutubeApiClient {
  YoutubeApiClient._(
    this._baseUrl,
    this._apiKey, {
    Map<String, String>? httpHeader,
  }) : _header = httpHeader ?? {"Accept": "application/json"};

  /// The host serving the Youtube Data API.
  final String _baseUrl;

  /// Headers used when performing a http request.
  final Map<String, String> _header;

  /// Identifies the app to Google, and is what the quota is counted against.
  ///
  /// Sent as a query parameter, so any URI built here carries it and must not
  /// be shown to the user or written anywhere it might be read.
  final String _apiKey;

  /// Create the client.
  static Future<YoutubeApiClient> create({
    String baseUrl = "www.googleapis.com",
    String apiKey = youtubeDataApiKey,
    Map<String, String>? httpHeader,
  }) async {
    return YoutubeApiClient._(baseUrl, apiKey, httpHeader: httpHeader);
  }

  // TODO: Remove once we introduce `provider`.
  static late final YoutubeApiClient instance;
  static Future<void> initialize() async {
    instance = await create();
  }

  /// Get the video with [id] from Youtube, or null if there is no such video.
  ///
  /// Cheap enough against the quota to be worth calling speculatively, which is
  /// how a pasted url or video id is told apart from something to search for.
  /// Null therefore means the id was not one, and is not a failure.
  ///
  /// Throws an [HttpException] if Youtube rejects the request, most often
  /// because the daily quota has been spent or the key has been revoked.
  Future<YoutubeVideo?> getVideoById(YoutubeVideoId id) async {
    // Generate search query
    final Json options = {
      "id": [id],
      "part": "snippet",
      "key": _apiKey,
      "type": "video",
    };
    Uri uri = Uri.https(_baseUrl, "youtube/v3/videos", options);

    final response = await http.get(uri, headers: _header);
    if (response.statusCode != 200) {
      throw HttpException(
        "Failed to get video '$id': ${response.statusCode}",
        uri: uri,
      );
    }

    var data = json.decode(response.body);
    if (data['error'] != null) {
      debugPrint(
        "[YOUTUBE] Error getting video with id '$id': ${data['error']['message']}",
      );
      return null;
    }

    if ((data['items'] as List?)?.isEmpty != false) return null;

    return YoutubeVideo.fromJson(data['items'][0] as Json);
  }

  /// Search Youtube for a given [query].
  ///
  /// A video that cannot be read is left out rather than failing the search, so
  /// one unusual result does not cost the user all the others. If every result
  /// fails, that is reported as a [FormatException]: it means the response no
  /// longer has the shape we expect, which should not be shown to the user as
  /// an empty search.
  ///
  /// Throws an [HttpException] if Youtube rejects the request, most often
  /// because the daily quota has been spent. The message is Youtube's own and
  /// is not written for the user.
  Future<List<YoutubeVideo>> search(
    String query, {
    String order = "relevance",
    String videoDuration = "any",
    int maxResults = 10,
  }) async {
    // Generate search query
    final Json options = {
      "q": query,
      "part": "snippet",
      "maxResults": "$maxResults",
      "key": _apiKey,
      "type": "video",
      "order": order,
      "videoDuration": videoDuration,
    };
    Uri uri = Uri.https(_baseUrl, "youtube/v3/search", options);

    // Do http get request
    final response = await http.get(uri, headers: _header);
    if (response.statusCode != 200) {
      throw HttpException(
        "Failed to search Youtube: ${response.statusCode}",
        uri: uri,
      );
    }
    var data = json.decode(response.body);
    if (data['error'] != null) {
      debugPrint("[YOUTUBE] Search failed: ${data['error']['message']}");
      throw HttpException(
        "Youtube search failed: ${data['error']['message']}",
        uri: uri,
      );
    }

    // Map result to [YoutubeVideo]s
    final List<dynamic>? items = data['items'] as List?;
    if (items == null) return [];

    final List<YoutubeVideo> videos = [];
    for (var video in items) {
      try {
        String kind = video['id']['kind'].substring(8) as String;
        if (kind == "video") {
          videos.add(
            YoutubeVideo.fromJson(
              video as Json,
              id: video['id']['videoId'] as String,
            ),
          );
        }
      } catch (e) {
        debugPrint("[YOUTUBE] Unable to parse video: $e");
      }
    }

    if (videos.isEmpty && items.isNotEmpty) {
      throw FormatException(
        "None of the ${items.length} videos Youtube returned could be read. "
        "The format of the response has likely changed.",
      );
    }

    return videos;
  }
}
