import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/services/file_cache_service.dart';

import '../../helpers/fixtures.dart';

void main() {
  late FileCacheService cache;
  late CacheFile file;

  setUp(() async {
    cache = await createTempFileCache();
    file = cache.scratch.file("nested/dir/file.json");
  });

  test("reads report null for a missing file", () async {
    expect(await file.exists(), isFalse);
    expect(await file.readString(), isNull);
    expect(await file.readBytes(), isNull);
    expect(await file.readJson(), isNull);
    expect(await file.size(), 0);
  });

  test("writes create parent directories and can be read back", () async {
    await file.writeJson({"a": 1, "b": "two"});
    expect(await file.readJson(), {"a": 1, "b": "two"});

    await file.writeBytes([1, 2, 3]);
    expect(await file.readBytes(), [1, 2, 3]);
    expect(await file.size(), 3);
  });

  test("concurrent writes are serialized, the last one winning", () async {
    await Future.wait([
      for (var i = 0; i < 5; i++) file.writeString("$i"),
    ]);
    expect(await file.readString(), "4");
  });

  test("a delete of a missing file does nothing", () async {
    await file.delete();
    await cache.scratch.directory("missing").delete();
  });

  group("ensure", () {
    test("produces the file only when it is absent", () async {
      var calls = 0;
      Future<void> produce(File scratch) async {
        calls++;
        await scratch.writeAsString("content");
      }

      await file.ensure(produce);
      await file.ensure(produce);

      expect(calls, 1);
      expect(await file.readString(), "content");
    });

    test("concurrent calls share one execution", () async {
      var calls = 0;
      await Future.wait([
        for (var i = 0; i < 3; i++)
          file.ensure((scratch) async {
            calls++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await scratch.writeAsString("x");
          }),
      ]);
      expect(calls, 1);
    });

    test("leaves nothing behind when production fails", () async {
      await expectLater(
        file.ensure((scratch) async {
          await scratch.writeAsString("partial");
          throw const FileSystemException("download failed");
        }),
        throwsA(isA<FileSystemException>()),
      );
      expect(await file.exists(), isFalse);
      expect(await cache.scratch.directory("nested").children(), isEmpty);
    });

    test("fails when nothing was written", () async {
      await expectLater(
        file.ensure((_) async {}),
        throwsA(isA<FileSystemException>()),
      );
      expect(await file.exists(), isFalse);
    });
  });

  test("names escaping the directory are rejected", () {
    expect(() => cache.scratch.file("../outside"), throwsArgumentError);
    expect(
      () => cache.persistent.directory("a/../../outside"),
      throwsArgumentError,
    );
  });

  test("directory size sums every file inside it", () async {
    final dir = cache.scratch.directory("sized");
    expect(await dir.size(), 0);

    await dir.file("a").writeBytes([1, 2]);
    await dir.file("sub/b").writeBytes([1, 2, 3]);
    expect(await dir.size(), 5);

    await dir.delete();
    expect(await dir.size(), 0);
  });
}
