import 'dart:math';

/// Representation of a musical note, with a given pitch.
class Note {
  /// Names of all notes, starting with A.
  static const List<String> noteNames = [
    "A",
    "Bb",
    "B",
    "C",
    "C#",
    "D",
    "Eb",
    "E",
    "F",
    "F#",
    "G",
    "G#"
  ];

  /// Create note from a given [frequency] in Hz.
  ///
  /// The frequency of A4 can be set to adjust the tuning. Defaults to 440 Hz.
  Note.fromFrequency(this.frequency, {this.a4frequency = 440});

  /// The frequency of A4, in Hz. Defaults to 440.
  final double a4frequency;

  /// The frequency of this note, in Hz.
  final double frequency;

  late final double _diffFromA4 = log(frequency / a4frequency) / log(2);

  /// Number of whole octaves between this note and A4.
  late final int octavesFromA4 = _diffFromA4.toInt();

  /// Number of whole semitones between this note and A4.
  late final int semitonesFromA4 = (12 * _diffFromA4).toInt();

  /// Number of whole cents between this note and A4.
  late final int centsFromA4 = (1200 * _diffFromA4).toInt();

  /// The name of this note, e.g C3.
  late final String name =
      "${noteNames[(semitonesFromA4 - 12 * octavesFromA4) % 12]}${octavesFromA4 + 4}";

  /// The error margin between this [frequency] and the closest semitone, in cents.
  late final int pitchOffset = centsFromA4 - semitonesFromA4 * 100;
}
