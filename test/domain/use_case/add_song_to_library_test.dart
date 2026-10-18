import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/domain/use_case/add_song_to_library.dart';
import 'package:musbx/utils/result.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/song_harness.dart';

void main() {
  setUpAll(registerFallbacks);

  late SongHarness h;
  late AddSongToLibrary addSong;
  final song = urlSong("a");

  setUp(() async {
    h = await SongHarness.create();
    addSong = AddSongToLibrary(
      songs: h.songs,
      settings: h.settings,
      demixing: h.demixing,
    );
  });

  test("adds the song and demixes it when that is automatic", () async {
    h.settings.songs.demixAutomatically = true;

    expect((await addSong(song)).asOk, song);
    expect(h.songs.getById("a"), song);
    verify(() => h.demixing.start(song)).called(1);
  });

  test("does not demix when that is not automatic", () async {
    h.settings.songs.demixAutomatically = false;

    await addSong(song).then((r) => r.asOk);
    verifyNever(() => h.demixing.start(any()));
  });

  test("still succeeds when demixing cannot start", () async {
    when(
      () => h.demixing.start(any()),
    ).thenReturn(Result.failed(Exception("offline")));

    expect(await addSong(song), isA<Ok<Object?>>());
    expect(h.songs.getById("a"), song);
  });
}
