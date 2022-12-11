import 'dart:math';

/// Representation of a musical note, with a given pitch.
class Note {
  /// The frequency of A4, in Hz. Used as a reference for all other notes.
  /// Defaults to 440 Hz.
  static double a4frequency = 440;

  /// Names of all notes, starting with A.
  static const List<String> noteNames = [
    "A",
    "B♭",
    "B",
    "C",
    "D♭",
    "D",
    "E♭",
    "E",
    "F",
    "G♭",
    "G",
    "A♭",
  ];

  /// Create note from a given [frequency] in Hz.
  /// [frequency] must be greater than 0.
  Note.fromFrequency(this.frequency)
      : assert(frequency > 0, "Frequency must be greater than 0");

  Note.relativeToA4(int semitonesFromA4)
      : frequency = a4frequency * pow(pow(2, 1 / 12), semitonesFromA4);

  /// The note with [a4frequency], used as a reference for all other notes.
  factory Note.a4() => Note.fromFrequency(a4frequency);

  /// The frequency of this note, in Hz.
  final double frequency;

  double get _diffFromA4 => log(frequency / a4frequency) / log(2);

  /// Number of whole octaves between this note and C4 (the note 3 semitones below A4).
  int get octavesFromC4 => ((semitonesFromA4 - 3) / 12).floor();

  /// Number of whole semitones between this note and A4.
  int get semitonesFromA4 => (12 * _diffFromA4).round();

  /// Number of whole cents between this note and A4.
  int get centsFromA4 => (1200 * _diffFromA4).round();

  /// The name of this note, e.g C3.
  String get name => "${noteNames[(semitonesFromA4) % 12]}${octavesFromC4 + 5}";

  /// The number of cents between this [frequency] and the closest semitone.
  double get pitchOffset => centsFromA4 - semitonesFromA4 * 100;

  Note operator +(Note other) =>
      Note.fromFrequency(frequency + other.frequency);

  Note operator -(Note other) =>
      Note.fromFrequency(frequency - other.frequency);
}
