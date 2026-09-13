import 'package:flutter/foundation.dart';
import 'package:musbx/data/repositories/demix/demixing_process.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/stem_type.dart';

class DemixRepository extends ChangeNotifier {
  DemixRepository({required SongCache cache}) : _cache = cache;

  final SongCache _cache;

  static final Map<Song, DemixingProcess> _processes = {};

  DemixingProcess start(Song song) {
    DemixingProcess? process = get(song);
    if (process?.isCancelled == true) process = null;

    process ??= DemixingProcess(song, cache: _cache);

    _processes[song] = process;
    notifyListeners();
    return process;
  }

  List<DemixingProcess> startAll(Iterable<Song> songs) =>
      songs.map(start).toList();

  DemixingProcess? get(Song song) => _processes[song];

  void cancel(Song song) {
    final process = _processes.remove(song);
    process?.cancel();
    notifyListeners();
  }

  Future<bool> hasStems(Song song) async => await stemsFor(song) != null;

  Future<Map<StemType, CacheFile>?> stemsFor(
    Song song, {
    String fileExtension = "mp3",
  }) async {
    final stems = {
      for (final stem in StemType.values) stem: _cache.stem(song, stem),
    };
    if ((await Future.wait(
      stems.values.map((f) => f.exists()),
    )).every((v) => v)) {
      return stems;
    }
    return null;
  }
}
