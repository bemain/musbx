import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';

void main() {
  late SongCache cache;
  late SongPreferencesRepository preferences;
  final song = urlSong("a");

  setUp(() async {
    cache = SongCache(fileCache: await createTempFileCache());
    preferences = SongPreferencesRepository(songCache: cache);
  });

  test("reads null for a song without preferences", () async {
    expect((await preferences.read(song)).asOk, isNull);
  });

  test("writes replace what was stored", () async {
    await preferences
        .write(song, const SongPreferences(speed: 0.5))
        .then((r) => r.asOk);
    await preferences
        .write(song, const SongPreferences(pitch: 3))
        .then((r) => r.asOk);

    final stored = (await preferences.read(song)).asOk;
    expect(stored?.pitch, 3);
    expect(stored?.speed, isNull);
  });

  test("survive clearing the song's cache", () async {
    await preferences
        .write(song, const SongPreferences(speed: 0.5))
        .then((r) => r.asOk);
    await cache.clear(song);
    expect((await preferences.read(song)).asOk?.speed, 0.5);
  });

  test("a corrupt file reads as a failure", () async {
    await cache.preferences(song).writeString("{not json");
    expect(await preferences.read(song), isA<Failure<SongPreferences?>>());
  });
}
