import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/domain/use_case/resume_demixing.dart';
import 'package:musbx/utils/result.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/song_harness.dart';

void main() {
  setUpAll(registerFallbacks);

  final requested = urlSong("requested");
  final declined = urlSong("declined");
  final undecided = urlSong("undecided");

  late SongHarness h;
  late ResumeDemixing resume;

  setUp(() async {
    final now = DateTime.now();
    h = await SongHarness.create(
      library: {
        requested: now,
        declined: now.subtract(const Duration(minutes: 1)),
        undecided: now.subtract(const Duration(minutes: 2)),
      },
    );
    for (final (song, shouldDemix) in [(requested, true), (declined, false)]) {
      await h.preferences
          .write(song, SongPreferences(shouldDemix: shouldDemix))
          .then((r) => r.asOk);
    }
    resume = ResumeDemixing(
      songs: h.songs,
      settings: h.settings,
      preferences: h.preferences,
      demixing: h.demixing,
    );
  });

  Future<Set<String>> started() async {
    await resume().then((r) => r.asOk);
    return {
      for (final call in verify(
        () => h.demixing.start(captureAny()),
      ).captured)
        (call as Song).id,
    };
  }

  test("an explicit choice wins over the setting", () async {
    h.settings.songs.demixAutomatically = false;
    expect(await started(), {"requested"});
  });

  test("undecided songs follow the setting", () async {
    h.settings.songs.demixAutomatically = true;
    expect(await started(), {"requested", "undecided"});
    verifyNever(() => h.demixing.start(declined));
    verifyNever(() => h.demixing.start(demoSong));
  });

  test("keeps going when one song fails to start", () async {
    h.settings.songs.demixAutomatically = true;
    when(
      () => h.demixing.start(requested),
    ).thenReturn(Result.failed(Exception("offline")));

    expect(await started(), contains("undecided"));
  });
}
