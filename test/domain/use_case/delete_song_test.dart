import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/domain/use_case/delete_song.dart';
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

  late DeleteSong delete;
  setUp(
    () => delete = DeleteSong(
      unloadSong: h.unloadSong,
      cache: h.cache,
      songs: h.songs,
      playback: h.playback,
      demixing: h.demixing,
    ),
  );

  test("removes the song and everything cached for it", () async {
    expect(await delete(song), isA<Ok<void>>());

    expect(h.playback.song, isNull);
    expect(h.songs.getById("a"), isNull);
    expect(await h.cache.audio(song).exists(), isFalse);
    expect((await h.preferences.read(song)).asOk, isNull);
    verify(() => h.demixing.cancel(song)).called(1);
  });

  test("leaves another loaded song playing", () async {
    final other = await h.localSong("b");
    await h.loadSong(other).then((r) => r.asOk);

    await delete(song).then((r) => r.asOk);
    expect(h.playback.song, other);
  });
}
