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

  /// The frequency for the note [semitonesFromA4] semitones from A4.
  double frequencyForNote(int semitonesFromA4) =>
      throw UnimplementedError("No implementation for frequencyForNote()");

  /// The number of cents between this [frequency] and the closest semitone.
  double pitchOffset(double frequency) =>
      throw UnimplementedError("No implementation for pitchOffset()");
}

class EqualTemperament extends Temperament {
  EqualTemperament({required super.a4frequency});

  @override
  double frequencyForNote(int semitonesFromA4) =>
      a4frequency * pow(pow(2, 1 / 12), semitonesFromA4);

  @override
  double pitchOffset(double frequency) {
    int centsFromA4 = (12 * log(frequency / a4frequency) / log(2)).round();
    return centsFromA4 - semitonesFromA4(frequency) * 100;
  }
}
