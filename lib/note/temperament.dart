import 'dart:math';

abstract class Temperament {
  /// Representation of a musical temperament, determining what frequencies notes are placed at.
  Temperament({required this.a4frequency});

  /// The frequency of A4, in Hz. Used as a reference for all other notes.
  final double a4frequency;

  /// The number of whole semitones between [frequency] and A4.
  int semitonesFromA4(double frequency) =>
      (12 * log(frequency / a4frequency) / log(2)).round();

  /// The number of whole octaves between [frequency] and C4 (the note 3 semitones below A4).
  int octavesFromC4(double frequency) =>
      ((semitonesFromA4(frequency) - 3) / 12).floor();

  /// The number of cents between this [frequency] and the closest semitone.
  double pitchOffset(double frequency) =>
      throw UnimplementedError("No implementation found for pitchOffset()");
}

class EqualTemperament extends Temperament {
  EqualTemperament({required super.a4frequency});

  @override
  double pitchOffset(double frequency) {
    int centsFromA4 = (12 * log(frequency / a4frequency) / log(2)).round();
    return centsFromA4 - semitonesFromA4(frequency) * 100;
  }
}
