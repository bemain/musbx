import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/repositories/analysis/analysis_repository_remote.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:musbx/data/services/musbx_api/jobs/analyze.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';

class MockMusbxApiClient extends Mock implements MusbxApiClient {}

class MockAnalyzeJob extends Mock implements AnalyzeJob {}

void main() {
  final handle = FileHandle.fromJson({
    "file": {"handle": "h"},
  });

  setUpAll(() {
    registerFallbackValue(File(""));
    registerFallbackValue(Uri());
    registerFallbackValue(handle);
  });

  late SongCache cache;
  late MockMusbxApiClient client;
  late MockAnalyzeJob job;
  late AnalysisRepositoryRemote analysis;

  setUp(() async {
    cache = SongCache(fileCache: await createTempFileCache());
    client = MockMusbxApiClient();
    job = MockAnalyzeJob();
    when(() => client.uploadYtdlp(any())).thenAnswer((_) async => handle);
    when(() => client.uploadFile(any())).thenAnswer((_) async => handle);
    when(() => client.analyze(handle)).thenAnswer((_) async => job);
    when(job.complete).thenAnswer((_) async => {0.0: "C", 1.5: "N"});
    analysis = AnalysisRepositoryRemote(
      cache: cache,
      getClient: () async => client,
    );
  });

  Map<Duration, String?> named(Result<Map<Duration, Object?>> result) =>
      result.asOk.map((key, chord) => MapEntry(key, chord?.toString()));

  group("chords", () {
    test("are read from the cache without contacting the server", () async {
      final song = urlSong("a");
      await cache.chords(song).writeJson({"0.0": "Am", "2.25": "N"});

      expect(named(await analysis.chords(song)), {
        Duration.zero: "Am",
        const Duration(milliseconds: 2250): null,
      });
      verifyZeroInteractions(client);
    });

    test("of a URL song are identified by the server and cached", () async {
      final song = urlSong("a");

      expect(named(await analysis.chords(song)), {
        Duration.zero: "C",
        const Duration(milliseconds: 1500): null,
      });
      verify(() => client.uploadYtdlp(Uri.parse("https://example.com/a")));
      expect(await cache.chords(song).readJson(), {"0.0": "C", "1.5": "N"});

      clearInteractions(client);
      await analysis.chords(song).then((r) => r.asOk);
      verifyZeroInteractions(client);
    });

    test("of a file song upload the cached audio", () async {
      final song = Song(id: "f", title: "F", audio: FileAudio(File("x.mp3")));

      await analysis.chords(song).then((r) => r.asOk);

      final uploaded =
          verify(() => client.uploadFile(captureAny())).captured.single
              as File;
      expect(uploaded.path, cache.audio(song).path);
    });

    test("fail when no server can be reached", () async {
      final unreachable = AnalysisRepositoryRemote(
        cache: cache,
        getClient: () async => throw Exception("offline"),
      );

      expect(await unreachable.chords(urlSong("a")), isA<Failure<Object?>>());
    });
  });

  test("waveform is unavailable off mobile", () async {
    expect(
      await analysis.waveform(urlSong("a")),
      isA<Unavailable<Waveform>>(),
    );
  });
}
