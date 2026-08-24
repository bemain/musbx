import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:musbx/data/models/soundcloud_track.dart';
import 'package:musbx/utils/utils.dart';

/// Thrown when a track has no format that can be downloaded.
///
/// SoundCloud serves Go+ and preview-only tracks over HLS exclusively, so no
/// progressive MP3 transcoding exists for them. Permanent — retrying will not
/// help, and the track cannot be added to the library.
class TrackNotDownloadableException implements Exception {
  const TrackNotDownloadableException(this.track);

  final SoundCloudTrack track;

  @override
  String toString() =>
      "No downloadable format for '${track.title}' (${track.id}), "
      "policy: ${track.policy}";
}

/// Searches SoundCloud and resolves tracks to something the app can download.
///
/// Talks to SoundCloud's internal API, which is neither documented nor
/// versioned: fields can disappear and endpoints can change without notice, so
/// everything read from a response is treated as untrusted.
///
/// The tracks handed back are [SoundCloudTrack], SoundCloud's own vocabulary
/// rather than the app's. Mapping them to domain models is the repository's
/// job; nothing above it should see this type.
class SoundCloudApiClient {
  SoundCloudApiClient._(this._baseUrl, this._clientId);

  /// Identifies the app to SoundCloud, and is required on every request.
  ///
  /// Scraped rather than issued, so it belongs to SoundCloud's own web player
  /// and can be revoked at any time, at which point every request starts
  /// failing until the service is created again.
  final String _clientId;

  /// Base URL for SoundCloud's API.
  final String _baseUrl;

  /// Create the client, obtaining a [_clientId] unless one is supplied.
  ///
  /// Performs network requests, and throws if no client id could be found.
  static Future<SoundCloudApiClient> create({
    String baseUrl = "https://api-v2.soundcloud.com",
    String? clientId,
  }) async {
    final c = clientId ?? await generateClientId();

    return SoundCloudApiClient._(baseUrl, c);
  }

  // TODO: Remove once we introduce `provider`.
  static late final SoundCloudApiClient instance;
  static Future<void> initialize() async {
    instance = await create();
  }

  /// Finds a client id by reading the one SoundCloud's own web player uses.
  ///
  /// SoundCloud issues no keys to third parties, so the id is recovered from
  /// the JavaScript bundles the site loads.
  ///
  /// Throws if no id could be found in any of the bundles.
  static Future<String> generateClientId() async {
    final response = await http.get(Uri.parse('https://soundcloud.com'));
    final jsUrlRegex = RegExp(r'https://a-v2\.sndcdn\.com/assets/[^"]+\.js');
    final jsUrls = jsUrlRegex.allMatches(response.body).map((m) => m.group(0));

    // Typically the client_id is in the last JS file loaded
    for (var url in jsUrls.toList().reversed) {
      final jsContent = await http.read(Uri.parse(url!));
      final idRegex = RegExp(r'client_id:"([a-zA-Z0-9]{32})"');
      if (idRegex.hasMatch(jsContent)) {
        return idRegex.firstMatch(jsContent)!.group(1)!;
      }
    }
    throw Exception("Could not scrape a SoundCloud client_id");
  }

  /// Searches for tracks on SoundCloud using the provided [query].
  ///
  /// A track that cannot be read is left out rather than failing the search, so
  /// one unusual result does not cost the user all the others. If every track
  /// fails, that is reported as a [FormatException]: it means the response no
  /// longer has the shape we expect, which should not be shown to the user as
  /// an empty result.
  ///
  /// Throws an [HttpException] if SoundCloud rejects the request.
  Future<List<SoundCloudTrack>> searchTracks(
    String query, {
    int limit = 50,
  }) async {
    final uri = Uri.parse("$_baseUrl/search/tracks").replace(
      queryParameters: {
        "q": query,
        "client_id": _clientId,
        "limit": "$limit",
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw HttpException(
        "Failed to search SoundCloud: ${response.statusCode}",
        uri: uri,
      );
    }

    final List<dynamic> data =
        json.decode(response.body)['collection'] as List<dynamic>;

    final List<SoundCloudTrack> tracks = [];
    for (final track in data) {
      try {
        tracks.add(SoundCloudTrack.fromJson(track as Json));
      } catch (e) {
        debugPrint("[SOUNDCLOUD] Unable to parse track: $e");
      }
    }

    if (tracks.isEmpty && data.isNotEmpty) {
      throw FormatException(
        "None of the ${data.length} tracks SoundCloud returned could be read. "
        "The format of the response has likely changed.",
      );
    }

    return tracks;
  }

  /// The URL the audio for [track] can be fetched from.
  ///
  /// The URL returned is short-lived and tied to [_clientId], so it is meant
  /// to be used immediately rather than stored.
  ///
  /// Of the formats SoundCloud offers, only progressive MP3 can be fetched as
  /// a single file; the rest are streamed in segments, which the app has no
  /// way to play. A [TrackNotDownloadableException] means the track has no
  /// such format and never will.
  ///
  /// Throws an [HttpException] if SoundCloud refuses to resolve the URL, which
  /// unlike the above is worth retrying.
  Future<Uri> getDownloadUrl(SoundCloudTrack track) async {
    final Uri uri =
        Uri.parse(
          track.transcodings
              .firstWhere(
                (t) =>
                    t.mimeType == "audio/mpeg" && t.protocol == "progressive",
                orElse: () => throw TrackNotDownloadableException(track),
              )
              .url,
        ).replace(
          queryParameters: {
            "client_id": _clientId,
          },
        );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException(
        "Failed to get SoundCloud download URL: ${res.statusCode}",
        uri: uri,
      );
    }

    return Uri.parse(json.decode(res.body)['url'] as String);
  }
}
