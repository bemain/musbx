import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/domain/models/music/chord.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/result.dart';

/// Musical analysis of a song: what is being played, and what it looks like.
/// The chord sounding at each point in time.
///
/// A `null` chord marks a stretch where no chord could be identified.
abstract class AnalysisRepository {
  Future<Result<Map<Duration, Chord?>>> chords(Song song);

  /// The amplitude envelope of the song, for drawing.
  Future<Result<Waveform>> waveform(Song song);
}
