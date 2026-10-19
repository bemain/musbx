import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/check_song_access.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/song_harness.dart';

void main() {
  setUpAll(registerFallbacks);

  final now = DateTime.now();
  final recent = [for (var i = 0; i < 3; i++) urlSong("recent$i")];
  final old = urlSong("old");
  final unplayed = urlSong("new");

  /// Access over a library where [recent] were played this week, [old] long
  /// ago, and the demo song just now.
  Future<CheckSongAccess> access({
    bool hasPremium = false,
    int recentCount = 3,
  }) async {
    final h = await SongHarness.create(
      library: {
        for (var i = 0; i < recentCount; i++)
          recent[i]: now.subtract(Duration(days: i + 1)),
        old: now.subtract(const Duration(days: 8)),
        demoSong: now,
      },
    );
    return CheckSongAccess(
      entitlement: FakeEntitlementRepository(hasPremium: hasPremium),
      songs: h.songs,
    );
  }

  test("only songs played within the week count, the demo excluded", () async {
    expect((await access()).playedThisWeek.toSet(), recent.toSet());
  });

  test("below the allowance any song can be played", () async {
    final check = await access(recentCount: 2);
    expect(check.isRestricted, isFalse);
    expect(check.canPlay(unplayed), isTrue);
  });

  group("with the allowance used up", () {
    late CheckSongAccess check;
    setUp(() async => check = await access());

    test("new and long-unplayed songs are refused", () {
      expect(check.isRestricted, isTrue);
      expect(check.canPlay(unplayed), isFalse);
      expect(check.canPlay(old), isFalse);
    });

    test("songs already played this week stay playable", () {
      expect(recent.every(check.canPlay), isTrue);
    });

    test("the demo song stays playable", () {
      expect(check.canPlay(demoSong), isTrue);
    });
  });

  test("premium is never restricted", () async {
    final check = await access(hasPremium: true);
    expect(check.isRestricted, isFalse);
    expect(check.canPlay(unplayed), isTrue);
  });

  test("songs are told apart by id", () async {
    final check = await access();
    final renamed = Song(
      id: recent.first.id,
      title: "Renamed",
      audio: recent.first.audio,
    );
    expect(check.canPlay(renamed), isTrue);
  });
}
