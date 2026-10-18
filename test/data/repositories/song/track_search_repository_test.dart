import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/models/soundcloud_track.dart';
import 'package:musbx/data/repositories/song/track_search_repository.dart';
import 'package:musbx/data/services/soundcloud_api_client.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';

class MockSoundCloudApiClient extends Mock implements SoundCloudApiClient {}

void main() {
  Future<TrackSearchRepository> create(SoundCloudApiClient client) async =>
      TrackSearchRepositorySoundCloud(
        apiClient: ServiceLoader(
          create: () async => client,
          fallback: SoundCloudApiClient.disabled,
        ),
        fileCache: await createTempFileCache(),
      );

  test("maps SoundCloud tracks, unescaping their text", () async {
    final client = MockSoundCloudApiClient();
    when(() => client.isEnabled).thenReturn(true);
    when(() => client.searchTracks("rock")).thenAnswer(
      (_) async => [
        const SoundCloudTrack(
          id: 42,
          title: "Rock &amp; Roll",
          username: "The &quot;Band&quot;",
          artworkUrl: "https://i1.sndcdn.com/art.jpg",
          permalinkUrl: "https://soundcloud.com/band/rock",
          duration: Duration(minutes: 3),
          policy: "SNIP",
          transcodings: [],
        ),
        const SoundCloudTrack(
          id: 7,
          title: "Plain",
          username: null,
          permalinkUrl: "https://soundcloud.com/x/plain",
          duration: null,
          policy: "ALLOW",
          transcodings: [],
        ),
      ],
    );

    final tracks = (await (await create(client)).searchTracks("rock")).asOk;

    expect(tracks.map((t) => t.id), ["42", "7"]);
    expect(tracks[0].title, "Rock & Roll");
    expect(tracks[0].artist, 'The "Band"');
    expect(tracks[0].artUri, Uri.parse("https://i1.sndcdn.com/art.jpg"));
    expect(tracks[0].sourceUrl, Uri.parse("https://soundcloud.com/band/rock"));
    expect(tracks[0].isPreview, isTrue);
    expect(tracks[1].artist, isNull);
    expect(tracks[1].artUri, isNull);
    expect(tracks[1].isPreview, isFalse);
  });

  test("a disabled client reports Unavailable", () async {
    final repository = await create(SoundCloudApiClient.disabled());
    expect(
      await repository.searchTracks("x"),
      isA<Unavailable<Object?>>(),
    );
  });
}
