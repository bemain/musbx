import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/repositories/song/song_settings_repository.dart';
import 'package:musbx/utils/result.dart';

class ResumeDemixing {
  ResumeDemixing({
    required SongRepository songs,
    required SongSettingsRepository settings,
    required SongPreferencesRepository preferences,
    required DemixRepository demixing,
  }) : _songs = songs,
       _settings = settings,
       _preferences = preferences,
       _demixing = demixing;

  final SongRepository _songs;
  final SongSettingsRepository _settings;
  final SongPreferencesRepository _preferences;
  final DemixRepository _demixing;

  Future<void> call() async {
    for (final song in _songs.getAll()) {
      final prefs = switch (await _preferences.read(song)) {
        Ok(:final value) => value,
        _ => null,
      };
      if (prefs?.shouldDemix ?? _settings.demixAutomatically) {
        _demixing.start(song);
      }
    }
  }
}
