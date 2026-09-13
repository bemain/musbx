import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/utils/result.dart';

/// Free up the space a song takes without removing it from the library.
///
/// Drops the downloaded audio, its stems and the analysis results, and stops
/// the song from being demixed again on its own. Its preferences are kept, so
/// reopening it restores where the user was.
class ClearSongCache {
  ClearSongCache({
    required SongCache cache,
    required SongPreferencesRepository preferences,
    required PlaybackRepository playback,
    required DemixRepository demixing,
  }) : _cache = cache,
       _preferences = preferences,
       _playback = playback,
       _demixing = demixing;

  final SongCache _cache;
  final SongPreferencesRepository _preferences;
  final PlaybackRepository _playback;
  final DemixRepository _demixing;

  Future<Result<void>> call(Song song) async {
    try {
      if (_playback.song == song) await _playback.unload();

      _demixing.cancel(song);
      await _cache.clear(song);

      final prefs = (await _preferences.read(song)).asOk;
      (await _preferences.write(
        song,
        prefs?.copyWith(shouldDemix: false) ??
            SongPreferences(shouldDemix: false),
      )).asOk;

      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
