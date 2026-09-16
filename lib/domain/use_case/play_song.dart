import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/check_song_access.dart';
import 'package:musbx/domain/use_case/load_song.dart';
import 'package:musbx/utils/result.dart';

/// Open a song and make it the most recently played one.
///
/// Fails with [Result.accessRestricted] when the user's free allowance is used
/// up; see [CheckSongAccess].
class PlaySong {
  PlaySong({
    required CheckSongAccess access,
    required LoadSong loadSong,
    required SongRepository songs,
  }) : _access = access,
       _loadSong = loadSong,
       _songs = songs;

  final CheckSongAccess _access;
  final LoadSong _loadSong;
  final SongRepository _songs;

  Future<Result<void>> call(Song song) async {
    if (!_access.canPlay(song)) return Result.accessRestricted();

    if (await _loadSong.call(song) case Failure<void> failure) return failure;

    return await _songs.add(song);
  }
}
