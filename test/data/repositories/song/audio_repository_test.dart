import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/repositories/song/audio_repository.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';

void main() {
  late FileCacheService fileCache;
  late AudioRepository audio;

  setUp(() async {
    fileCache = await createTempFileCache();
    audio = AudioRepository(
      musbxApi: offlineMusbxApi(),
      songCache: SongCache(fileCache: fileCache),
    );
  });

  test("copies a local file into the cache", () async {
    final source = File(fileCache.persistent.file("in.mp3").path);
    await source.create(recursive: true);
    await source.writeAsBytes([1, 2, 3]);
    final song = Song(id: "f", title: "F", audio: FileAudio(source));

    final resolved = (await audio.resolve(song)).asOk;
    expect(resolved.path, isNot(source.path));
    expect(await resolved.readAsBytes(), [1, 2, 3]);

    await source.delete();
    expect(await (await audio.resolve(song)).asOk.readAsBytes(), [1, 2, 3]);
  });

  test("fails for a local file that does not exist", () async {
    final song = Song(
      id: "f",
      title: "F",
      audio: FileAudio(File("/does/not/exist.mp3")),
    );
    final result = await audio.resolve(song);
    expect(
      result,
      isA<Failure<File>>().having(
        (f) => f.error,
        "error",
        isA<FileSystemException>(),
      ),
    );
  });

  test("writes bytes into the cache", () async {
    final song = Song(
      id: "b",
      title: "B",
      audio: BytesAudio(Uint8List.fromList([4, 5])),
    );
    expect(await (await audio.resolve(song)).asOk.readAsBytes(), [4, 5]);
  });

  test("fails for bytes that are gone and were never cached", () async {
    final song = Song(id: "b", title: "B", audio: BytesAudio(null));
    expect(await audio.resolve(song), isA<Failure<File>>());
  });
}
