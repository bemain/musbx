import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/models/soundcloud_track.dart';

void main() {
  test("reads a full API response", () {
    final track = SoundCloudTrack.fromJson({
      "id": 1,
      "title": "Title",
      "user": {"username": "artist"},
      "artwork_url": "https://art",
      "permalink_url": "https://soundcloud.com/a/b",
      "duration": 90500,
      "streamable": true,
      "policy": "SNIP",
      "media": {
        "transcodings": [
          {
            "url": "https://stream",
            "format": {"mime_type": "audio/mpeg", "protocol": "progressive"},
            "quality": "sq",
          },
        ],
      },
    });

    expect(track.username, "artist");
    expect(track.duration, const Duration(milliseconds: 90500));
    expect(track.streamable, isTrue);
    expect(track.downloadable, isFalse);
    expect(track.isPreview, isTrue);
    expect(track.transcodings.single.protocol, "progressive");
    expect(track.transcodings.single.mimeType, "audio/mpeg");
  });

  test("tolerates missing optional fields", () {
    final track = SoundCloudTrack.fromJson({
      "id": 1,
      "title": "Title",
      "permalink_url": "https://soundcloud.com/a/b",
    });

    expect(track.username, isNull);
    expect(track.duration, isNull);
    expect(track.isPreview, isFalse);
    expect(track.transcodings, isEmpty);
  });
}
