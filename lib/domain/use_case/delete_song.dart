import 'package:flutter/foundation.dart';
import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/unload_song.dart';
import 'package:musbx/utils/result.dart';

/// Remove a song from the library and delete everything cached for it.
///
/// Closes the song first if it is the one open.
class DeleteSong {
  DeleteSong({
    required UnloadSong unloadSong,
    required SongCache cache,
    required SongRepository songs,
    required PlaybackRepository playback,
    required DemixRepository demixing,
  }) : _unloadSong = unloadSong,
       _cache = cache,
       _songs = songs,
       _playback = playback,
       _demixing = demixing;

  final UnloadSong _unloadSong;
  final SongCache _cache;
  final SongRepository _songs;
  final PlaybackRepository _playback;
  final DemixRepository _demixing;

  Future<Result<void>> call(Song song) async {
    try {
      if (_playback.song == song) {
        if (await _unloadSong.call() case Failure(:final error)) {
          debugPrint("[SONGS] Unloading song failed; $error");
        }
      }

      if (await _songs.remove(song) case Failure<void> failure) return failure;
      _demixing.cancel(song);
      await _cache.delete(song);
      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
