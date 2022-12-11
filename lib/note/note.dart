import 'dart:math';

import 'package:musbx/note/temperament.dart';

/// Representation of a musical note, with a given pitch.
class Note {
  /// The frequency of A4, in Hz. Used as a reference for all other notes.
  /// Defaults to 440 Hz.
  static double a4frequency = 440;

  static Temperament temperament = EqualTemperament(a4frequency: a4frequency);

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

  /// The name of this note, e.g C3.
  String get name =>
      "${noteNames[(temperament.semitonesFromA4(frequency)) % 12]}${temperament.octavesFromC4(frequency) + 5}";

  /// The number of cents between this [frequency] and the closest semitone.
  double get pitchOffset => temperament.pitchOffset(frequency);

  Note operator +(Note other) =>
      Note.fromFrequency(frequency + other.frequency);

  Note operator -(Note other) =>
      Note.fromFrequency(frequency - other.frequency);
}
