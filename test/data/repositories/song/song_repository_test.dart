import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/domain/models/online_track.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';

void main() {
  late FileCacheService fileCache;
  late SongRepository songs;
  final a = urlSong("a");
  final b = urlSong("b");

  setUp(() async {
    fileCache = await createTempFileCache();
    songs = await SongRepository.create(fileCache: fileCache);
  });

  test("an empty library is seeded with the demo song", () {
    expect(songs.getAll(), [demoSong]);
  });

  test("songs are ordered by when they were last played", () async {
    await songs.add(a).then((r) => r.asOk);
    await songs.add(b).then((r) => r.asOk);
    expect(songs.getAll(), [b, a, demoSong]);
    expect(songs.getAll(order: GetOrder.ascending), [demoSong, a, b]);
  });

  test("adding a song again moves it to the top", () async {
    await songs.add(a).then((r) => r.asOk);
    await songs.add(b).then((r) => r.asOk);
    await songs.add(a).then((r) => r.asOk);
    expect(songs.getAll(), [a, b, demoSong]);
  });

  test("the library survives a restart", () async {
    await songs.add(a).then((r) => r.asOk);
    await songs.add(b).then((r) => r.asOk);

    final reopened = await SongRepository.create(fileCache: fileCache);
    expect(reopened.getAll(), [b, a, demoSong]);
    expect(reopened.getById("a")?.title, a.title);
  });

  test("update replaces a song without moving it", () async {
    await songs.add(a).then((r) => r.asOk);
    await songs
        .update(demoSong.copyWith(title: "Renamed"))
        .then((r) => r.asOk);

    expect(songs.getAll(), [a, demoSong]);
    expect(songs.getById(demoSong.id)?.title, "Renamed");
  });

  test("remove takes the song out of the library", () async {
    await songs.add(a).then((r) => r.asOk);
    expect(await songs.remove(a), isA<Ok<void>>());
    expect(songs.getById("a"), isNull);
  });

  test("addFile titles the song after the file", () async {
    final song = (await songs.addFile(File("/music/My Song.mp3"))).asOk;
    expect(song.title, "My Song");
    expect((song.audio as FileAudio).file.path, "/music/My Song.mp3");

    final again = (await songs.addFile(File("/music/My Song.mp3"))).asOk;
    expect(again.id, song.id);
  });

  test("addTrack keeps the track's id and metadata", () async {
    final song = (await songs.addTrack(
      OnlineTrack(
        id: "sc-1",
        title: "Track",
        artist: "Someone",
        sourceUrl: Uri.parse("https://soundcloud.com/x"),
      ),
    )).asOk;

    expect(songs.getById("sc-1"), song);
    expect(song.artist, "Someone");
    expect(
      (song.audio as UrlAudio).url,
      Uri.parse("https://soundcloud.com/x"),
    );
  });

  test("getWhere sees when each song was played", () async {
    fileCache = await createTempFileCache();
    final now = DateTime.now();
    await seedLibrary(fileCache, {
      a: now.subtract(const Duration(days: 10)),
      b: now,
    });
    songs = await SongRepository.create(fileCache: fileCache);

    expect(
      songs.getWhere((_, playedAt) => now.difference(playedAt).inDays < 7),
      [b],
    );
  });

  test("unreadable entries are skipped", () async {
    fileCache = await createTempFileCache();
    await fileCache.persistent.file("songs/history.json").writeJson({
      DateTime(2026).toString(): a.toJson(),
      DateTime(2025).toString(): {"id": "broken"},
      "not a date": b.toJson(),
    });

    songs = await SongRepository.create(fileCache: fileCache);
    expect(songs.getAll(), [a]);
  });

  test("notifies listeners when the library changes", () async {
    var notifications = 0;
    songs.addListener(() => notifications++);
    await songs.add(a).then((r) => r.asOk);
    await songs.remove(a).then((r) => r.asOk);
    expect(notifications, 2);
  });
}
