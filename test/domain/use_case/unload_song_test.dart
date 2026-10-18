import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/utils/result.dart';

import '../../helpers/mocks.dart';
import '../../helpers/song_harness.dart';

void main() {
  setUpAll(registerFallbacks);

  late SongHarness h;
  setUp(() async => h = await SongHarness.create());

  test("does nothing when no song is loaded", () async {
    expect(await h.unloadSong(), isA<Ok<void>>());
  });

  test("stops the song and saves how it was left", () async {
    final song = await h.localSong("a");
    await h.loadSong(song).then((r) => r.asOk);
    h.playback
      ..pitch = 2
      ..setPart(Part.vocals, enabled: false);

    await h.unloadSong().then((r) => r.asOk);

    expect(h.playback.song, isNull);
    final saved = (await h.preferences.read(song)).asOk;
    expect(saved?.pitch, 2);
    expect(saved?.parts?[Part.vocals]?.enabled, isFalse);
  });
}
