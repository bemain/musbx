import 'package:meta/meta.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/utils/result.dart';

class ClearSongCache {
  ClearSongCache({
    required SongCache cache,
    required SongPreferencesRepository preferences,
  }) : _cache = cache,
       _preferences = preferences;

  final SongCache _cache;

  final SongPreferencesRepository _preferences;

  @useResult
  Future<Result<void>> call(Song song) async {
    try {
      DemixingProcesses.cancel(song);
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
