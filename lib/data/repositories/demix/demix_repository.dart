import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/repositories/demix/demixing_process.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/musbx_api_service.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

/// The parts separated out of each song, and the demixing processes producing
/// them.
///
/// At most one process runs per song; asking for one that is already running
/// returns it rather than starting a second. Processes outlive the repository
/// instance, so demixing survives a rebuild of the provider tree.
class DemixRepository extends ChangeNotifier {
  DemixRepository({
    required SongCache cache,
    required MusbxApiService musbxApi,
  }) : _cache = cache,
       _musbxApi = musbxApi;

  final SongCache _cache;
  final MusbxApiService _musbxApi;

  static final Map<Song, DemixingProcess> _processes = {};

  /// Start demixing [song], or return the process already doing so.
  ///
  /// A cancelled process is replaced rather than resumed.
  @useResult
  Result<DemixingProcess> start(Song song) {
    try {
      DemixingProcess? process = get(song);
      if (process?.isCancelled == true) process = null;

      process ??= DemixingProcess(song, cache: _cache, musbxApi: _musbxApi);

      _processes[song] = process;
      notifyListeners();
      return Result.ok(process);
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  /// [start] every one of [songs].
  @useResult
  Result<List<DemixingProcess>> startAll(Iterable<Song> songs) {
    try {
      return Result.ok(songs.map((song) => start(song).asOk).toList());
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  /// The process demixing [song], if there is one.
  DemixingProcess? get(Song song) => _processes[song];

  /// Stop demixing [song] and forget the process.
  void cancel(Song song) {
    final process = _processes.remove(song);
    process?.cancel();
    notifyListeners();
  }

  /// Whether every part of [song] is present in the cache.
  Future<bool> hasParts(Song song) async => await partsFor(song) != null;

  /// The cached part files for [song], or `null` unless all of them are present.
  Future<Map<Part, CacheFile>?> partsFor(Song song) => _cache.parts(song);
}
