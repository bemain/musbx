import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
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
  });

  test("loads the song with its stored preferences", () async {
    await h.preferences
        .write(song, const SongPreferences(speed: 0.75))
        .then((r) => r.asOk);

    expect(await h.loadSong(song), isA<Ok<void>>());
    expect(h.playback.song, song);
    expect(h.playback.speed, 0.75);
    expect(await h.cache.audio(song).exists(), isTrue);
  });

  test("saves the previous song's preferences before replacing it", () async {
    await h.loadSong(song).then((r) => r.asOk);
    h.playback.speed = 1.25;

    final other = await h.localSong("b");
    await h.loadSong(other).then((r) => r.asOk);

    expect(h.playback.song, other);
    expect((await h.preferences.read(song)).asOk?.speed, 1.25);
  });

  test("plays the parts when every one is cached", () async {
    final parts = {for (final p in Part.values) p: h.cache.part(song, p)};
    when(() => h.demixing.partsFor(song)).thenAnswer((_) async => parts);

    await h.loadSong(song).then((r) => r.asOk);

    expect(h.playback.isMulti, isTrue);
  });

  test("fails without loading when the audio cannot be found", () async {
    final missing = Song(
      id: "missing",
      title: "Missing",
      audio: FileAudio(File("/does/not/exist.mp3")),
    );

    expect(await h.loadSong(missing), isA<Failure<void>>());
    expect(h.playback.song, isNull);
  });
}
