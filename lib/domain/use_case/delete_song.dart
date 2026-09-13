import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

class DeleteSong {
  DeleteSong({
    required SongCache cache,
    required DemixRepository demixing,
  }) : _cache = cache,
       _demixing = demixing;

  final SongCache _cache;
  final DemixRepository _demixing;

  Future<Result<void>> call(Song song) async {
    try {
      _demixing.cancel(song);
      await _cache.delete(song);
      return Result.ok(null);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
