import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/domain/models/song.dart';

import '../../../helpers/fixtures.dart';

void main() {
  late SongCache cache;
  late DemixRepository demixing;
  // Processes are shared between repository instances, so each test needs
  // songs of its own.
  var nextId = 0;
  late Song song;

  Future<void> cacheParts(Song song) async {
    for (final part in Part.values) {
      await cache.part(song, part).writeBytes([0]);
    }
  }

  setUp(() async {
    cache = SongCache(fileCache: await createTempFileCache());
    demixing = DemixRepository(cache: cache);
    song = urlSong("demix-${nextId++}");
    // With every part cached a process finishes without reaching the server.
    await cacheParts(song);
  });

  test("a cached song demixes to its cached parts", () async {
    final process = demixing.start(song).asOk;
    final parts = (await process.future).asOk;
    expect(parts.keys, Part.values);
    expect(await demixing.hasParts(song), isTrue);
  });

  test("starting twice returns the running process", () {
    final first = demixing.start(song).asOk;
    expect(demixing.start(song).asOk, same(first));
    expect(DemixRepository(cache: cache).get(song), same(first));
  });

  test("a cancelled process is replaced", () {
    final first = demixing.start(song).asOk..cancel();
    final second = demixing.start(song).asOk;
    expect(second, isNot(same(first)));
    expect(first.isCancelled, isTrue);
  });

  test("cancel stops and forgets the process", () {
    final process = demixing.start(song).asOk;
    demixing.cancel(song);
    expect(process.isCancelled, isTrue);
    expect(demixing.get(song), isNull);
  });

  test("startAll starts one process per song", () async {
    final other = urlSong("demix-${nextId++}");
    await cacheParts(other);
    expect(demixing.startAll([song, other]).asOk, hasLength(2));
  });

  test("hasParts is false while any part is missing", () async {
    await cache.part(song, Part.drums).delete();
    expect(await demixing.hasParts(song), isFalse);
  });
}
