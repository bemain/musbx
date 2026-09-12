import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/repositories/song/song_settings_repository.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/utils/result.dart';

class AddSongToLibrary {
  AddSongToLibrary({
    required SongRepository songs,
    required SongSettingsRepository settings,
  }) : _songs = songs,
       _settings = settings;

  final SongRepository _songs;

  final SongSettingsRepository _settings;

  Future<Result<Song>> call(Song song) async {
    final result = await _songs.add(song);
    if (result case Ok(:final value) when _settings.demixAutomatically) {
      DemixingProcesses.start(value);
    }
    return result;
  }
}
