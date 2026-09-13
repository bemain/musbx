import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/domain/models/music/chord.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

abstract class AnalysisRepository {
  Future<Result<Map<Duration, Chord?>>> chords(Song song);

  Future<Result<Waveform>> waveform(Song song);
}
