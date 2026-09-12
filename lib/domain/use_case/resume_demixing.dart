import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/repositories/song/song_settings_repository.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/utils/result.dart';

class ResumeDemixing {
  ResumeDemixing({
    required SongRepository songs,
    required SongSettingsRepository settings,
    required SongPreferencesRepository preferences,
  }) : _songs = songs,
       _settings = settings,
       _preferences = preferences;

  final SongRepository _songs;

  final SongSettingsRepository _settings;

  final SongPreferencesRepository _preferences;

  Future<void> call() async {
    for (final song in _songs.getAll()) {
      final prefs = switch (await _preferences.read(song)) {
        Ok(:final value) => value,
        _ => null,
      };
      if (prefs?.shouldDemix ?? _settings.demixAutomatically) {
        DemixingProcesses.start(song);
      }
    }
  }
}
