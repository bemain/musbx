import 'package:meta/meta.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/routing/router.dart';
import 'package:musbx/utils/result.dart';

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

      // Close the song
      libraryNavigatorKey.currentState?.popUntil((route) => route.isFirst);

      final prefs = _playback.readPreferences();

      await _playback.stop();

      // Save preferences
      (await _songPreferences.write(song, prefs)).asOk;

      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
