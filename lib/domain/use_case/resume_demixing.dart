import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/utils/result.dart';

/// Pick demixing back up where the last session left it.
///
/// Run at startup. A song is demixed again if it was asked for explicitly, or,
/// when nothing was asked either way, if the user demixes automatically.
class ResumeDemixing {
  ResumeDemixing({
    required SongRepository songs,
    required SettingsRepository settings,
    required SongPreferencesRepository preferences,
    required DemixRepository demixing,
  }) : _songs = songs,
       _settings = settings,
       _preferences = preferences,
       _demixing = demixing;

  final SongRepository _songs;
  final SettingsRepository _settings;
  final SongPreferencesRepository _preferences;
  final DemixRepository _demixing;

  Future<void> call() async {
    for (final song in _songs.getAll()) {
      final prefs = switch (await _preferences.read(song)) {
        Ok(:final value) => value,
        _ => null,
      };
      if (prefs?.shouldDemix ?? _settings.songs.demixAutomatically) {
        _demixing.start(song);
      }
    }
  }
}
