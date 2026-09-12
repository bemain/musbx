import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/songs/demixer/process_handler.dart';

class ClearSongCache {
  ClearSongCache({
    required SongCache cache,
  }) : _cache = cache;

  final SongCache _cache;

  Future<void> call(Song song) async {
    DemixingProcesses.cancel(song);
    await _cache.clear(song);
  }
}
