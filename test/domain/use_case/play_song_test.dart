import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/check_song_access.dart';
import 'package:musbx/domain/use_case/play_song.dart';
import 'package:musbx/utils/result.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/song_harness.dart';

void main() {
  setUpAll(registerFallbacks);

  late SongHarness h;

  PlaySong playSong() => PlaySong(
    access: CheckSongAccess(
      entitlement: FakeEntitlementRepository(),
      songs: h.songs,
    ),
    loadSong: h.loadSong,
    songs: h.songs,
  );

  test("loads the song and moves it to the top of the library", () async {
    h = await SongHarness.create();
    final song = await h.localSong("a");

    expect(await playSong()(song), isA<Ok<void>>());
    expect(h.playback.song, song);
    expect(h.songs.getAll().first, song);
  });

  test("refuses when the allowance is used up", () async {
    final now = DateTime.now();
    h = await SongHarness.create(
      library: {
        for (var i = 0; i < 3; i++)
          urlSong("$i"): now.subtract(Duration(minutes: i)),
      },
    );
    final song = await h.localSong("a");

    expect(await playSong()(song), isA<AccessRestricted<void>>());
    expect(h.playback.song, isNull);
    expect(h.songs.getById("a"), isNull);
  });

  test("leaves the library alone when loading fails", () async {
    h = await SongHarness.create();
    final missing = Song(
      id: "missing",
      title: "Missing",
      audio: FileAudio(File("/does/not/exist.mp3")),
    );

    expect(await playSong()(missing), isA<Failure<void>>());
    expect(h.songs.getAll(), [demoSong]);
  });
}
