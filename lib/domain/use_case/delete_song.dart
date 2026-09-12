import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/songs/demixer/process_handler.dart';
import 'package:musbx/utils/result.dart';

class DeleteSong {
  DeleteSong({
    required SongCache cache,
  }) : _cache = cache;

  final SongCache _cache;

  Future<Result<void>> call(Song song) async {
    try {
      DemixingProcesses.cancel(song);
      await _cache.delete(song);
      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
