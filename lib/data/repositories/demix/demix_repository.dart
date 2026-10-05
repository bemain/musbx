import 'package:flutter/foundation.dart';
import 'package:musbx/data/repositories/demix/demixing_process.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/stem_type.dart';

/// The stems separated out of each song, and the demixing processes producing
/// them.
///
/// At most one process runs per song; asking for one that is already running
/// returns it rather than starting a second. Processes outlive the repository
/// instance, so demixing survives a rebuild of the provider tree.
class DemixRepository extends ChangeNotifier {
  DemixRepository({required SongCache cache}) : _cache = cache;

  final SongCache _cache;

  static final Map<Song, DemixingProcess> _processes = {};

  /// Start demixing [song], or return the process already doing so.
  ///
  /// A cancelled process is replaced rather than resumed.
  DemixingProcess start(Song song) {
    DemixingProcess? process = get(song);
    if (process?.isCancelled == true) process = null;

    process ??= DemixingProcess(song, cache: _cache);

    _processes[song] = process;
    notifyListeners();
    return process;
  }

  /// [start] every one of [songs].
  List<DemixingProcess> startAll(Iterable<Song> songs) =>
      songs.map(start).toList();

  /// The process demixing [song], if there is one.
  DemixingProcess? get(Song song) => _processes[song];

  /// Stop demixing [song] and forget the process.
  void cancel(Song song) {
    final process = _processes.remove(song);
    process?.cancel();
    notifyListeners();
  }

  /// Whether every stem of [song] is present in the cache.
  Future<bool> hasStems(Song song) async => await stemsFor(song) != null;

  /// The cached stem files for [song], or `null` unless all of them are present.
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
