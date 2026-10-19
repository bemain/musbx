import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/domain/use_case/clear_song_cache.dart';
import 'package:musbx/utils/result.dart';

import '../../helpers/mocks.dart';
import '../../helpers/song_harness.dart';

void main() {
  setUpAll(registerFallbacks);

  late SongHarness h;
  late Song song;

  setUp(() async {
    h = await SongHarness.create();
    song = await h.localSong("a");
    await h.songs.add(song).then((r) => r.asOk);
    await h.preferences
        .write(song, const SongPreferences(speed: 0.5, shouldDemix: true))
        .then((r) => r.asOk);
    await h.loadSong(song).then((r) => r.asOk);
  });

  late ClearSongCache clear;
  setUp(
    () => clear = ClearSongCache(
      unloadSong: h.unloadSong,
      cache: h.cache,
      preferences: h.preferences,
      playback: h.playback,
      demixing: h.demixing,
    ),
  );

  test("drops the cached audio but keeps the song", () async {
    expect(await clear(song), isA<Ok<void>>());

    expect(h.playback.song, isNull);
    expect(h.songs.getById("a"), song);
    expect(await h.cache.audio(song).exists(), isFalse);
    verify(() => h.demixing.cancel(song)).called(1);
  });

  test("keeps preferences but stops automatic demixing", () async {
    await clear(song).then((r) => r.asOk);

    final saved = (await h.preferences.read(song)).asOk;
    expect(saved?.speed, 0.5);
    expect(saved?.shouldDemix, isFalse);
  });

  test("works for a song that never had preferences", () async {
    final other = await h.localSong("b");
    await clear(other).then((r) => r.asOk);
    expect((await h.preferences.read(other)).asOk?.shouldDemix, isFalse);
  });
}
