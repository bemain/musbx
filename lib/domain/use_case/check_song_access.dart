import 'package:musbx/data/repositories/entitlement/entitlement_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/domain/models/song.dart';

class CheckSongAccess {
  CheckSongAccess({
    required EntitlementRepository entitlement,
    required SongRepository songs,
  }) : _entitlement = entitlement,
       _songs = songs;

  final EntitlementRepository _entitlement;
  final SongRepository _songs;

  static const int freeSongsPerWeek = 3;
  static const Duration window = Duration(days: 7);

  Iterable<Song> get playedThisWeek => _songs
      .getWhere(
        (song, accessedAt) => DateTime.now().difference(accessedAt) < window,
      )
      .where((song) => song != demoSong);

  bool get isRestricted =>
      !_entitlement.hasPremium && playedThisWeek.length >= freeSongsPerWeek;

  bool canPlay(Song song) =>
      song == demoSong || !isRestricted || playedThisWeek.contains(song);
}
