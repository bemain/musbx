import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/part.dart';

import '../../helpers/fixtures.dart';

void main() {
  late SongCache cache;
  final song = urlSong("a");
  final other = urlSong("b");

  setUp(() async {
    cache = SongCache(fileCache: await createTempFileCache());
    await cache.audio(song).writeBytes([1, 2, 3]);
    await cache.chords(song).writeJson({});
    await cache.preferences(song).writeJson({});
  });

  test("parts is null unless every part is cached", () async {
    for (final part in Part.values.skip(1)) {
      await cache.part(song, part).writeBytes([0]);
    }
    expect(await cache.parts(song), isNull);

    await cache.part(song, Part.values.first).writeBytes([0]);
    expect(await cache.parts(song), hasLength(Part.values.length));
  });

  test("clear drops regenerable files but keeps preferences", () async {
    await cache.clear(song);

    expect(await cache.audio(song).exists(), isFalse);
    expect(await cache.chords(song).exists(), isFalse);
    expect(await cache.preferences(song).exists(), isTrue);
    expect(await cache.size(song), 0);
  });

  test("delete drops everything for that song only", () async {
    await cache.audio(other).writeBytes([1]);

    await cache.delete(song);

    expect(await cache.preferences(song).exists(), isFalse);
    expect(await cache.audio(other).exists(), isTrue);
  });

  test("size counts regenerable files across songs", () async {
    await cache.audio(other).writeBytes([1, 2]);
    expect(await cache.size(song), 3 + 2); // audio + "{}"
    expect(await cache.totalSize(), 7);

    await cache.clearAll();
    expect(await cache.totalSize(), 0);
  });
}
