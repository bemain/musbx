import 'package:musbx/domain/models/audio_frame.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/models/music/temperament.dart';

class TunerReading {
  TunerReading({
    required this.pitch,
    required this.offset,
    required this.frame,
  });

  final Pitch? pitch;

  final double? offset;

  final AudioFrame frame;

  factory TunerReading.fromFrequency(
    double? frequency, {
    required AudioFrame frame,
    Pitch tuning = const Pitch.a440(),
    Temperament temperament = const EqualTemperament(),
    Accidental? preferredAccidental,
  }) {
    if (frequency == null) {
      return TunerReading(pitch: null, offset: null, frame: frame);
    }

    final pitch = Pitch.closest(
      frequency,
      tuning: tuning,
      temperament: temperament,
      preferredAccidental: preferredAccidental,
    );
    return TunerReading(
      frame: frame,
      pitch: pitch,
      offset: pitch.offsetFrom(
        tuning.frequency *
            temperament.frequencyRatio(tuning.semitonesTo(pitch)),
      ),
    );
  }
}
