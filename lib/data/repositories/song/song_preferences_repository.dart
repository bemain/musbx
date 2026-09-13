import 'package:meta/meta.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/utils/utils.dart';

class SongPreferencesRepository {
  SongPreferencesRepository({required SongCache songCache})
    : _songCache = songCache;

  final SongCache _songCache;

  CacheFile _songFile(Song song) => _songCache.preferences(song);

  @useResult
  Future<Result<SongPreferences?>> read(Song song) async {
    try {
      final Json? json = await _songFile(song).readJson();
      if (json == null) return Result.ok(null);
      return Result.ok(SongPreferences.fromJson(json));
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  @useResult
  Future<Result<void>> write(Song song, SongPreferences preferences) async {
    try {
      await _songFile(song).writeJson(preferences.toJson());

      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
