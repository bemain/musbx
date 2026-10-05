import 'package:musbx/data/repositories/entitlement/entitlement_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/domain/models/song.dart';

/// Whether the user is allowed to play a given song.
///
/// Without premium, only [freeSongsPerWeek] distinct songs can be played per
/// rolling [window]. A song already played inside the window stays playable, so
/// the limit is on how many songs are picked up, not on how much they are
/// played. [demoSong] never counts and is always playable.
class CheckSongAccess {
  CheckSongAccess({
    required EntitlementRepository entitlement,
    required SongRepository songs,
  }) : _entitlement = entitlement,
       _songs = songs;

  final EntitlementRepository _entitlement;
  final SongRepository _songs;

  /// How many distinct songs can be played per [window] without premium.
  static const int freeSongsPerWeek = 3;

  /// How far back the free song count reaches.
  static const Duration window = Duration(days: 7);

  /// The songs played within the last [window], excluding [demoSong].
  Iterable<Song> get playedThisWeek => _songs
      .getWhere(
        (song, accessedAt) => DateTime.now().difference(accessedAt) < window,
      )
      .where((song) => song != demoSong);

  /// Whether the free allowance is used up, so that no further song can be
  /// started.
  bool get isRestricted =>
      !_entitlement.hasPremium && playedThisWeek.length >= freeSongsPerWeek;

  /// Whether [song] can be played right now.
  bool canPlay(Song song) =>
      song == demoSong || !isRestricted || playedThisWeek.contains(song);
}
