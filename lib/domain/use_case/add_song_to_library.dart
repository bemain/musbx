import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/repositories/song/song_settings_repository.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

class AddSongToLibrary {
  AddSongToLibrary({
    required SongRepository songs,
    required SongSettingsRepository settings,
    required DemixRepository demixing,
  }) : _songs = songs,
       _settings = settings,
       _demixing = demixing;

  final SongRepository _songs;
  final SongSettingsRepository _settings;
  final DemixRepository _demixing;

  Future<Result<Song>> call(Song song) async {
    final result = await _songs.add(song);
    if (result case Ok(:final value) when _settings.demixAutomatically) {
      _demixing.start(value);
    }
    return result;
  }
}
