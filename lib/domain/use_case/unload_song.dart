import 'package:meta/meta.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/utils/result.dart';

/// Stop the loaded song, saving its preferences. Does nothing if no song is
/// loaded.
class UnloadSong {
  UnloadSong({
    required SongPreferencesRepository songPreferences,
    required PlaybackRepository playback,
  }) : _songPreferences = songPreferences,
       _playback = playback;

  final SongPreferencesRepository _songPreferences;
  final PlaybackRepository _playback;

  @useResult
  Future<Result<void>> call() async {
    try {
      final song = _playback.song;
      if (song == null) return Result.ok(null);

      final prefs = _playback.readPreferences();

      if (await _playback.stop() case final Failure<void> failure) {
        return failure;
      }

      // Save preferences
      (await _songPreferences.write(song, prefs)).asOk;

      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
