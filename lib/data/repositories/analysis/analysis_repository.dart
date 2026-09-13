import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/data/repositories/analysis/analysis_repository_remote.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/domain/models/music/chord.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

abstract class AnalysisRepository {
  // TODO: Remove once we introduce 'provider'
  static final AnalysisRepository instance = AnalysisRepositoryRemote(
    cache: SongCache.instance,
  );

  Future<Result<Map<Duration, Chord?>>> chords(Song song);

  Future<Result<Waveform>> waveform(Song song);
}
