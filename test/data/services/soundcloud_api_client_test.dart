import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:musbx/data/models/soundcloud_track.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/soundcloud_api_client.dart';
import 'package:musbx/utils/utils.dart';

Json trackJson(
  int id, {
  List<(String mimeType, String protocol)> formats = const [
    ("audio/mpeg", "progressive"),
  ],
}) => {
  "id": id,
  "title": "Track $id",
  "permalink_url": "https://soundcloud.com/a/$id",
  "media": {
    "transcodings": [
      for (final (mimeType, protocol) in formats)
        {
          "url": "https://stream/$id/$protocol",
          "format": {"mime_type": mimeType, "protocol": protocol},
          "quality": "sq",
        },
    ],
  },
};

void main() {
  final List<http.Request> requests = [];

  /// Run [body] with every request answered by [respond] and recorded in
  /// [requests].
  Future<T> withServer<T>(
    http.Response Function(http.Request request) respond,
    Future<T> Function() body,
  ) => http.runWithClient(
    body,
    () => MockClient((request) async {
      requests.add(request);
      return respond(request);
    }),
  );

  late SoundCloudApiClient client;

  setUp(() async {
    requests.clear();
    client = SoundCloudApiClient.createWith("id", baseUrl: "https://api.test");
  });

  group("searchTracks", () {
    test("sends the query and reads the tracks", () async {
      final tracks = await withServer(
        (_) => http.Response(
          jsonEncode({
            "collection": [trackJson(1), trackJson(2)],
          }),
          200,
        ),
        () => client.searchTracks("bach", limit: 2),
      );

      expect(tracks.map((t) => t.id), [1, 2]);
      final uri = requests.single.url;
      expect(uri.path, "/search/tracks");
      expect(uri.queryParameters, {
        "q": "bach",
        "client_id": "id",
        "limit": "2",
      });
    });

    test("leaves out tracks that cannot be read", () async {
      final tracks = await withServer(
        (_) => http.Response(
          jsonEncode({
            "collection": [
              trackJson(1),
              {"id": "not a track"},
            ],
          }),
          200,
        ),
        () => client.searchTracks("bach"),
      );

      expect(tracks.map((t) => t.id), [1]);
    });

    test("reports a changed response format when no track can be read", () {
      expect(
        withServer(
          (_) => http.Response(
            jsonEncode({
              "collection": [
                {"id": "not a track"},
              ],
            }),
            200,
          ),
          () => client.searchTracks("bach"),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test("an empty result is not an error", () async {
      final tracks = await withServer(
        (_) => http.Response(jsonEncode({"collection": <Object>[]}), 200),
        () => client.searchTracks("nothing"),
      );
      expect(tracks, isEmpty);
    });

    test("throws when SoundCloud rejects the request", () {
      expect(
        withServer(
          (_) => http.Response("", 401),
          () => client.searchTracks("bach"),
        ),
        throwsA(isA<HttpException>()),
      );
    });
  });

  group("getDownloadUrl", () {
    test("resolves the progressive MP3 transcoding", () async {
      final track = SoundCloudTrack.fromJson(
        trackJson(
          1,
          formats: [("audio/mpeg", "hls"), ("audio/mpeg", "progressive")],
        ),
      );

      final url = await withServer(
        (_) => http.Response(jsonEncode({"url": "https://cdn/1.mp3"}), 200),
        () => client.getDownloadUrl(track),
      );

      expect(url, Uri.parse("https://cdn/1.mp3"));
      expect(
        requests.single.url,
        Uri.parse("https://stream/1/progressive?client_id=id"),
      );
    });

    test("refuses a track that is only streamed in segments", () async {
      final track = SoundCloudTrack.fromJson(
        trackJson(1, formats: [("audio/mpeg", "hls")]),
      );

      await expectLater(
        withServer(
          (_) => http.Response("", 200),
          () => client.getDownloadUrl(track),
        ),
        throwsA(isA<TrackNotDownloadableException>()),
      );
      expect(requests, isEmpty);
    });

    test("throws when SoundCloud refuses to resolve it", () {
      final track = SoundCloudTrack.fromJson(trackJson(1));

      expect(
        withServer(
          (_) => http.Response("", 500),
          () => client.getDownloadUrl(track),
        ),
        throwsA(isA<HttpException>()),
      );
    });
  });

  group("generateClientId", () {
    const id = "abcdefghijklmnopqrstuvwxyz012345";

    test("reads the id from the bundles the site loads", () async {
      final generated = await withServer(
        (request) => switch (request.url.toString()) {
          "https://soundcloud.com" => http.Response(
            '<script src="https://a-v2.sndcdn.com/assets/1-a.js"></script>'
            '<script src="https://a-v2.sndcdn.com/assets/2-b.js"></script>',
            200,
          ),
          "https://a-v2.sndcdn.com/assets/1-a.js" => http.Response(
            'client_id:"$id"',
            200,
          ),
          _ => http.Response("nothing here", 200),
        },
        SoundCloudApiClient.generateClientId,
      );

      expect(generated, id);
      // The last bundle is searched first.
      expect(requests.map((r) => r.url.pathSegments.lastOrNull), [
        null,
        "2-b.js",
        "1-a.js",
      ]);
    });

    test("throws when no bundle holds an id", () {
      expect(
        withServer(
          (_) => http.Response("no scripts", 200),
          SoundCloudApiClient.generateClientId,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group("disabled", () {
    final disabled = SoundCloudApiClient.disabled();

    test("is not enabled", () => expect(disabled.isEnabled, isFalse));

    test("throws without making a request", () async {
      final track = SoundCloudTrack.fromJson(trackJson(1));
      await withServer((_) => http.Response("", 200), () async {
        await expectLater(
          disabled.searchTracks("bach"),
          throwsA(isA<ServiceDisabled>()),
        );
        await expectLater(
          disabled.getDownloadUrl(track),
          throwsA(isA<ServiceDisabled>()),
        );
      });
      expect(requests, isEmpty);
    });
  });
}
